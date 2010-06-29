package SimCodeC

protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {});

public import Tpl;

public import SimCode;
public import DAELow;
public import System;
public import Absyn;
public import DAE;
public import ClassInf;
public import Util;
public import Exp;
public import RTOpts;

public function translateModel
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(name = i_modelInfo_name), functions = i_functions)) )
      local
        list<SimCode.Function> i_functions;
        String i_modelInfo_name;
        SimCode.SimCode i_simCode;
        Tpl.Text txt_6;
        Tpl.Text txt_5;
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text i_filePrefix;
      equation
        i_filePrefix = Tpl.writeStr(emptyTxt, i_modelInfo_name);
        txt_1 = simulationFile(emptyTxt, i_simCode);
        txt_2 = Tpl.writeText(emptyTxt, i_filePrefix);
        txt_2 = Tpl.writeTok(txt_2, Tpl.ST_STRING(".cpp"));
        Tpl.textFile(txt_1, Tpl.textString(txt_2));
        txt_3 = simulationFunctionsFile(emptyTxt, i_functions);
        txt_4 = Tpl.writeText(emptyTxt, i_filePrefix);
        txt_4 = Tpl.writeTok(txt_4, Tpl.ST_STRING("_functions.cpp"));
        Tpl.textFile(txt_3, Tpl.textString(txt_4));
        txt_5 = simulationMakefile(emptyTxt, i_simCode);
        txt_6 = Tpl.writeText(emptyTxt, i_filePrefix);
        txt_6 = Tpl.writeTok(txt_6, Tpl.ST_STRING(".makefile"));
        Tpl.textFile(txt_5, Tpl.textString(txt_6));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateModel;

public function translateFunctions
  input Tpl.Text in_txt;
  input SimCode.FunctionCode in_i_functionCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_functionCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_functionCode as SimCode.FUNCTIONCODE(name = i_name, functions = i_functions, extraRecordDecls = i_extraRecordDecls)) )
      local
        list<SimCode.RecordDeclaration> i_extraRecordDecls;
        list<SimCode.Function> i_functions;
        String i_name;
        SimCode.FunctionCode i_functionCode;
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text i_filePrefix;
      equation
        i_filePrefix = Tpl.writeStr(emptyTxt, i_name);
        txt_1 = functionsFile(emptyTxt, i_functions, i_extraRecordDecls);
        txt_2 = Tpl.writeText(emptyTxt, i_filePrefix);
        txt_2 = Tpl.writeTok(txt_2, Tpl.ST_STRING(".c"));
        Tpl.textFile(txt_1, Tpl.textString(txt_2));
        txt_3 = functionsMakefile(emptyTxt, i_functionCode);
        txt_4 = Tpl.writeText(emptyTxt, i_filePrefix);
        txt_4 = Tpl.writeTok(txt_4, Tpl.ST_STRING(".makefile"));
        Tpl.textFile(txt_3, Tpl.textString(txt_4));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateFunctions;

public function simulationFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = i_modelInfo, extObjInfo = i_extObjInfo, allEquations = i_allEquations, nonStateContEquations = i_nonStateContEquations, removedEquations = i_removedEquations, algorithmAndEquationAsserts = i_algorithmAndEquationAsserts, nonStateDiscEquations = i_nonStateDiscEquations, zeroCrossings = i_zeroCrossings, zeroCrossingsNeedSave = i_zeroCrossingsNeedSave, helpVarInfo = i_helpVarInfo, allEquationsPlusWhen = i_allEquationsPlusWhen, discreteModelVars = i_discreteModelVars, delayedExps = i_delayedExps, whenClauses = i_whenClauses, stateContEquations = i_stateContEquations, initialEquations = i_initialEquations, residualEquations = i_residualEquations, parameterEquations = i_parameterEquations)) )
      local
        list<SimCode.SimEqSystem> i_parameterEquations;
        list<SimCode.SimEqSystem> i_residualEquations;
        list<SimCode.SimEqSystem> i_initialEquations;
        list<SimCode.SimEqSystem> i_stateContEquations;
        list<SimCode.SimWhenClause> i_whenClauses;
        SimCode.DelayedExpression i_delayedExps;
        list<DAE.ComponentRef> i_discreteModelVars;
        list<SimCode.SimEqSystem> i_allEquationsPlusWhen;
        list<SimCode.HelpVarInfo> i_helpVarInfo;
        list<list<SimCode.SimVar>> i_zeroCrossingsNeedSave;
        list<DAELow.ZeroCrossing> i_zeroCrossings;
        list<SimCode.SimEqSystem> i_nonStateDiscEquations;
        list<DAE.Statement> i_algorithmAndEquationAsserts;
        list<SimCode.SimEqSystem> i_removedEquations;
        list<SimCode.SimEqSystem> i_nonStateContEquations;
        list<SimCode.SimEqSystem> i_allEquations;
        SimCode.ExtObjInfo i_extObjInfo;
        SimCode.ModelInfo i_modelInfo;
        SimCode.SimCode i_simCode;
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
        txt = functionUpdateDepend(txt, i_allEquationsPlusWhen);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionOnlyZeroCrossing(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionCheckForDiscreteChanges(txt, i_discreteModelVars);
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
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationFile;

protected function lm_14
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_include :: rest )
      local
        list<String> rest;
        String i_include;
      equation
        txt = Tpl.writeStr(txt, i_include);
        txt = Tpl.nextIter(txt);
        txt = lm_14(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_14(txt, rest);
      then txt;
  end matchcontinue;
end lm_14;

public function simulationFileHeader
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(name = i_modelInfo_name), extObjInfo = SimCode.EXTOBJINFO(includes = i_extObjInfo_includes)) )
      local
        list<String> i_extObjInfo_includes;
        String i_modelInfo_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("// Simulation code for "));
        txt = Tpl.writeStr(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " generated by the OpenModelica Compiler.\n",
                                    "\n",
                                    "#include \"modelica.h\"\n",
                                    "#include \"assert.h\"\n",
                                    "#include \"string.h\"\n",
                                    "#include \"simulation_runtime.h\"\n",
                                    "\n",
                                    "#if defined(_MSC_VER) && !defined(_SIMULATION_RUNTIME_H)\n",
                                    "  #define DLLExport   __declspec( dllexport )\n",
                                    "#else\n",
                                    "  #define DLLExport /* nothing */\n",
                                    "#endif\n",
                                    "\n",
                                    "#include \""
                                }, false));
        txt = Tpl.writeStr(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_functions.cpp\"\n",
                                    "\n",
                                    "extern \"C\" {\n"
                                }, true));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_14(txt, i_extObjInfo_includes);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationFileHeader;

protected function lm_16
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "states");
        txt = Tpl.nextIter(txt);
        txt = lm_16(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_16(txt, rest);
      then txt;
  end matchcontinue;
end lm_16;

protected function lm_17
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "statesDerivatives");
        txt = Tpl.nextIter(txt);
        txt = lm_17(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_17(txt, rest);
      then txt;
  end matchcontinue;
end lm_17;

protected function lm_18
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_18(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_18(txt, rest);
      then txt;
  end matchcontinue;
end lm_18;

protected function lm_19
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_19(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "extObjs");
        txt = Tpl.nextIter(txt);
        txt = lm_20(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "stringVariables.algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_21(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = globalDataVarDefine(txt, i_var, "stringVariables.parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_22(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_23(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_24(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_25(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isFixed;
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_26(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_26(txt, rest);
      then txt;
  end matchcontinue;
end lm_26;

protected function smf_27
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_27;

protected function smf_28
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_28;

protected function smf_29
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_29;

protected function smf_30
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_30;

protected function lm_31
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_31(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_32(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
        Boolean i_isDiscrete;
        DAE.ExpType i_type__;
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_33(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_33(txt, rest);
      then txt;
  end matchcontinue;
end lm_33;

protected function smf_34
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_34;

protected function smf_35
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_35;

protected function smf_36
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;

    case ( txt,
           i_it )
      local
        Tpl.Text i_it;
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_36;

public function globalData
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(varInfo = SimCode.VARINFO(numHelpVars = i_varInfo_numHelpVars, numZeroCrossings = i_varInfo_numZeroCrossings, numTimeEvents = i_varInfo_numTimeEvents, numStateVars = i_varInfo_numStateVars, numAlgVars = i_varInfo_numAlgVars, numParams = i_varInfo_numParams, numOutVars = i_varInfo_numOutVars, numInVars = i_varInfo_numInVars, numResiduals = i_varInfo_numResiduals, numExternalObjects = i_varInfo_numExternalObjects, numStringAlgVars = i_varInfo_numStringAlgVars, numStringParamVars = i_varInfo_numStringParamVars), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, inputVars = i_vars_inputVars, outputVars = i_vars_outputVars, paramVars = i_vars_paramVars, stringAlgVars = i_vars_stringAlgVars, stringParamVars = i_vars_stringParamVars, extObjVars = i_vars_extObjVars), name = i_name, directory = i_directory) )
      local
        String i_directory;
        String i_name;
        list<SimCode.SimVar> i_vars_extObjVars;
        list<SimCode.SimVar> i_vars_stringParamVars;
        list<SimCode.SimVar> i_vars_stringAlgVars;
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_outputVars;
        list<SimCode.SimVar> i_vars_inputVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
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
        Tpl.Text txt_6;
        Tpl.Text txt_5;
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
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
                                    "\n",
                                    "static DATA* localData = 0;\n",
                                    "#define time localData->timeValue\n",
                                    "extern \"C\" { // adrpo: this is needed for Visual C++ compilation to work!\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char *model_name=\""));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\";\n",
                                    "const char *model_dir=\""
                                }, false));
        txt = Tpl.writeStr(txt, i_directory);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
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
        txt = globalDataVarCommentsArray(txt, "string_alg_comments", i_vars_stringAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "string_param_comments", i_vars_stringParamVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_16(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_17(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_18(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_19(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_20(txt, i_vars_extObjVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_21(txt, i_vars_stringAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_22(txt, i_vars_stringParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "static char init_fixed[NX+NX+NY+NP] = {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt_0 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_0 = lm_23(txt_0, i_vars_stateVars);
        txt_0 = Tpl.popIter(txt_0);
        txt_1 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_1 = lm_24(txt_1, i_vars_derivativeVars);
        txt_1 = Tpl.popIter(txt_1);
        txt_2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_25(txt_2, i_vars_algVars);
        txt_2 = Tpl.popIter(txt_2);
        txt_3 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_3 = lm_26(txt_3, i_vars_paramVars);
        txt_3 = Tpl.popIter(txt_3);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = smf_27(txt, txt_0);
        txt = smf_28(txt, txt_1);
        txt = smf_29(txt, txt_2);
        txt = smf_30(txt, txt_3);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "\n",
                                    "char var_attr[NX+NY+NP] = {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt_4 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_4 = lm_31(txt_4, i_vars_stateVars);
        txt_4 = Tpl.popIter(txt_4);
        txt_5 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_5 = lm_32(txt_5, i_vars_algVars);
        txt_5 = Tpl.popIter(txt_5);
        txt_6 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_6 = lm_33(txt_6, i_vars_paramVars);
        txt_6 = Tpl.popIter(txt_6);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = smf_34(txt, txt_4);
        txt = smf_35(txt, txt_5);
        txt = smf_36(txt, txt_6);
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

protected function lm_38
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      local
        list<SimCode.SimVar> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_38(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_38(txt, rest);
      then txt;
  end matchcontinue;
end lm_38;

protected function fun_39
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_i_items;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_items, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           {},
           i_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("[1] = {\"\"};"));
      then txt;

    case ( txt,
           i_items,
           i_name )
      local
        list<SimCode.SimVar> i_items;
        Integer ret_1;
        Tpl.Text i_itemsStr;
      equation
        i_itemsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_itemsStr = lm_38(i_itemsStr, i_items);
        i_itemsStr = Tpl.popIter(i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        ret_1 = listLength(i_items);
        txt = Tpl.writeStr(txt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.writeText(txt, i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;
  end matchcontinue;
end fun_39;

public function globalDataVarNamesArray
  input Tpl.Text txt;
  input String i_name;
  input list<SimCode.SimVar> i_items;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_39(txt, i_items, i_name);
end globalDataVarNamesArray;

protected function lm_41
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(comment = i_comment) :: rest )
      local
        list<SimCode.SimVar> rest;
        String i_comment;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeStr(txt, i_comment);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_41(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_41(txt, rest);
      then txt;
  end matchcontinue;
end lm_41;

protected function fun_42
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_i_items;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_items, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           {},
           i_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("[1] = {\"\"};"));
      then txt;

    case ( txt,
           i_items,
           i_name )
      local
        list<SimCode.SimVar> i_items;
        Integer ret_1;
        Tpl.Text i_itemsStr;
      equation
        i_itemsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_itemsStr = lm_41(i_itemsStr, i_items);
        i_itemsStr = Tpl.popIter(i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        ret_1 = listLength(i_items);
        txt = Tpl.writeStr(txt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.writeText(txt, i_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;
  end matchcontinue;
end fun_42;

public function globalDataVarCommentsArray
  input Tpl.Text txt;
  input String i_name;
  input list<SimCode.SimVar> i_items;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_42(txt, i_items, i_name);
end globalDataVarCommentsArray;

public function globalDataVarDefine
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;
  input String in_i_arrayName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_arrayName)
    local
      Tpl.Text txt;
      String i_arrayName;

    case ( txt,
           (i_s as SimCode.SIMVAR(arrayCref = SOME(i_c), index = i_index)),
           i_arrayName )
      local
        Integer i_index;
        DAE.ComponentRef i_c;
        SimCode.SimVar i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = cref(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define "
                                }, false));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(index = i_index)),
           i_arrayName )
      local
        Integer i_index;
        SimCode.SimVar i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, i_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
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
  input Boolean in_i_isFixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_isFixed)
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
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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
  input Boolean in_i_isDiscrete;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_isDiscrete)
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

protected function lm_48
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(index = i_index)) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        SimCode.SimVar i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return state_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_48(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(index = i_index)) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        SimCode.SimVar i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return derivative_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_49(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(index = i_index)) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        SimCode.SimVar i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return algvars_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_50(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(index = i_index)) :: rest )
      local
        list<SimCode.SimVar> rest;
        Integer i_index;
        SimCode.SimVar i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return param_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_51(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_51(txt, rest);
      then txt;
  end matchcontinue;
end lm_51;

public function functionGetName
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars)) )
      local
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "const char* getName(double* ptr)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_48(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_49(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_50(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_51(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return \"\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
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
                                   "\n",
                                   "  if(flags & STATES && returnData->nStates) {\n",
                                   "    returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->oldStates = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->oldStates2 = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    assert(returnData->states&&returnData->oldStates&&returnData->oldStates2);\n",
                                   "    memset(returnData->states,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->oldStates,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->oldStates2,0,sizeof(double)*returnData->nStates);\n",
                                   "  } else {\n",
                                   "    returnData->states = 0;\n",
                                   "    returnData->oldStates = 0;\n",
                                   "    returnData->oldStates2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESDERIVATIVES && returnData->nStates) {\n",
                                   "    returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->oldStatesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->oldStatesDerivatives2 = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    assert(returnData->statesDerivatives&&returnData->oldStatesDerivatives&&returnData->oldStatesDerivatives2);\n",
                                   "    memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->oldStatesDerivatives,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->oldStatesDerivatives2,0,sizeof(double)*returnData->nStates);\n",
                                   "  } else {\n",
                                   "    returnData->statesDerivatives = 0;\n",
                                   "    returnData->oldStatesDerivatives = 0;\n",
                                   "    returnData->oldStatesDerivatives2 = 0;\n",
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
                                   "    returnData->oldAlgebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    returnData->oldAlgebraics2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    assert(returnData->algebraics&&returnData->oldAlgebraics&&returnData->oldAlgebraics2);\n",
                                   "    memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "    memset(returnData->oldAlgebraics,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "    memset(returnData->oldAlgebraics2,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->algebraics = 0;\n",
                                   "    returnData->oldAlgebraics = 0;\n",
                                   "    returnData->oldAlgebraics2 = 0;\n",
                                   "    returnData->stringVariables.algebraics = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & ALGEBRAICS && returnData->stringVariables.nAlgebraic) {\n",
                                   "    returnData->stringVariables.algebraics = (char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);\n",
                                   "    assert(returnData->stringVariables.algebraics);\n",
                                   "    memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->stringVariables.algebraics=0;\n",
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
                                   "        returnData->stringVariables.parameters = (char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);\n",
                                   "      assert(returnData->stringVariables.parameters);\n",
                                   "      memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);\n",
                                   "  } else {\n",
                                   "      returnData->stringVariables.parameters=0;\n",
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
                                   "  if(flags & PARAMETERSNAMES) {\n",
                                   "    returnData->parametersNames = param_names;\n",
                                   "  } else {\n",
                                   "    returnData->parametersNames = 0;\n",
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
                                   "  if(flags & PARAMETERSCOMMENTS) {\n",
                                   "    returnData->parametersComments = param_comments;\n",
                                   "  } else {\n",
                                   "    returnData->parametersComments = 0;\n",
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

protected function lm_56
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_arg;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_arg, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_56(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_56(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_56;

protected function lm_57
  input Tpl.Text in_txt;
  input list<SimCode.ExtConstructor> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           (i_var, i_fnName, i_args) :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.ExtConstructor> rest;
        list<DAE.Exp> i_args;
        String i_fnName;
        DAE.ComponentRef i_var;
        Tpl.Text i_argsStr;
      equation
        i_argsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argsStr, i_varDecls, i_preExp) = lm_56(i_argsStr, i_args, i_varDecls, i_preExp);
        i_argsStr = Tpl.popIter(i_argsStr);
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, i_fnName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_argsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_57(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.ExtConstructor> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_57(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_57;

protected function lm_58
  input Tpl.Text in_txt;
  input list<SimCode.ExtAlias> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var1, i_var2) :: rest )
      local
        list<SimCode.ExtAlias> rest;
        DAE.ComponentRef i_var2;
        DAE.ComponentRef i_var1;
      equation
        txt = cref(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = cref(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_58(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.ExtAlias> rest;
      equation
        txt = lm_58(txt, rest);
      then txt;
  end matchcontinue;
end lm_58;

public function functionCallExternalObjectConstructors
  input Tpl.Text in_txt;
  input SimCode.ExtObjInfo in_i_extObjInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extObjInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.EXTOBJINFO(constructors = i_constructors, aliases = i_aliases) )
      local
        list<SimCode.ExtAlias> i_aliases;
        list<SimCode.ExtConstructor> i_constructors;
        Tpl.Text i_ctorCalls;
        Tpl.Text i_preExp;
        Tpl.Text i_varDecls;
      equation
        i_varDecls = emptyTxt;
        i_preExp = emptyTxt;
        i_ctorCalls = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_ctorCalls, i_varDecls, i_preExp) = lm_57(i_ctorCalls, i_constructors, i_varDecls, i_preExp);
        i_ctorCalls = Tpl.popIter(i_ctorCalls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "/* Has to be performed after _init.txt file has been read */\n",
                                    "void callExternalObjectConstructors(DATA* localData) {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_ctorCalls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_58(txt, i_aliases);
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

protected function lm_60
  input Tpl.Text in_txt;
  input list<SimCode.ExtDestructor> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_fnName, i_var) :: rest )
      local
        list<SimCode.ExtDestructor> rest;
        DAE.ComponentRef i_var;
        String i_fnName;
      equation
        txt = Tpl.writeStr(txt, i_fnName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_60(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.ExtDestructor> rest;
      equation
        txt = lm_60(txt, rest);
      then txt;
  end matchcontinue;
end lm_60;

public function functionDeInitializeDataStruc
  input Tpl.Text in_txt;
  input SimCode.ExtObjInfo in_i_extObjInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extObjInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.EXTOBJINFO(destructors = i_destructors) )
      local
        list<SimCode.ExtDestructor> i_destructors;
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
                                    "  if(flags & STATES && data->oldStates) {\n",
                                    "    free(data->oldStates);\n",
                                    "    data->oldStates = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATES && data->oldStates2) {\n",
                                    "    free(data->oldStates2);\n",
                                    "    data->oldStates2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->statesDerivatives) {\n",
                                    "    free(data->statesDerivatives);\n",
                                    "    data->statesDerivatives = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->oldStatesDerivatives) {\n",
                                    "    free(data->oldStatesDerivatives);\n",
                                    "    data->oldStatesDerivatives = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->oldStatesDerivatives2) {\n",
                                    "    free(data->oldStatesDerivatives2);\n",
                                    "    data->oldStatesDerivatives2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->algebraics) {\n",
                                    "    free(data->algebraics);\n",
                                    "    data->algebraics = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->oldAlgebraics) {\n",
                                    "    free(data->oldAlgebraics);\n",
                                    "    data->oldAlgebraics = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->oldAlgebraics2) {\n",
                                    "    free(data->oldAlgebraics2);\n",
                                    "    data->oldAlgebraics2 = 0;\n",
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
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_60(txt, i_destructors);
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

protected function lm_62
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_62(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_62(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_62;

protected function lm_63
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_63(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_63(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_63;

protected function lm_64
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_64(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_64(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_64;

public function functionDaeOutput
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_nonStateContEquations;
  input list<SimCode.SimEqSystem> i_removedEquations;
  input list<DAE.Statement> i_algorithmAndEquationAsserts;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_removedPart;
  Tpl.Text i_algAndEqAssertsPart;
  Tpl.Text i_nonStateContPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_nonStateContPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_nonStateContPart, i_varDecls) := lm_62(i_nonStateContPart, i_nonStateContEquations, i_varDecls);
  i_nonStateContPart := Tpl.popIter(i_nonStateContPart);
  i_algAndEqAssertsPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_algAndEqAssertsPart, i_varDecls) := lm_63(i_algAndEqAssertsPart, i_algorithmAndEquationAsserts, i_varDecls);
  i_algAndEqAssertsPart := Tpl.popIter(i_algAndEqAssertsPart);
  i_removedPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_removedPart, i_varDecls) := lm_64(i_removedPart, i_removedEquations, i_varDecls);
  i_removedPart := Tpl.popIter(i_removedPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for continuous time variables */\n",
                                   "int functionDAE_output()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_nonStateContPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_algAndEqAssertsPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_removedPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionDaeOutput;

protected function lm_66
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_66(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_66(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_66;

protected function lm_67
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_67(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_67(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_67;

public function functionDaeOutput2
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_nonStateDiscEquations;
  input list<SimCode.SimEqSystem> i_removedEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_removedPart;
  Tpl.Text i_nonSateDiscPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_nonSateDiscPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_nonSateDiscPart, i_varDecls) := lm_66(i_nonSateDiscPart, i_nonStateDiscEquations, i_varDecls);
  i_nonSateDiscPart := Tpl.popIter(i_nonSateDiscPart);
  i_removedPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_removedPart, i_varDecls) := lm_67(i_removedPart, i_removedEquations, i_varDecls);
  i_removedPart := Tpl.popIter(i_removedPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for discrete time variables */\n",
                                   "int functionDAE_output2()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_nonSateDiscPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_removedPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionDaeOutput2;

protected function lm_69
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(name = _)) :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_s;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = localData->inputVars["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_69(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_69(txt, rest);
      then txt;
  end matchcontinue;
end lm_69;

public function functionInput
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(inputVars = i_vars_inputVars)) )
      local
        list<SimCode.SimVar> i_vars_inputVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int input_function()\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_69(txt, i_vars_inputVars);
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

protected function lm_71
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(name = _)) :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_s;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->outputVars["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_71(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_71(txt, rest);
      then txt;
  end matchcontinue;
end lm_71;

public function functionOutput
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(outputVars = i_vars_outputVars)) )
      local
        list<SimCode.SimVar> i_vars_outputVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int output_function()\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_71(txt, i_vars_outputVars);
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
                                   "  double* statesBackup;\n",
                                   "  double* statesDerivativesBackup;\n",
                                   "  double timeBackup;\n",
                                   "\n",
                                   "  statesBackup = localData->states;\n",
                                   "  statesDerivativesBackup = localData->statesDerivatives;\n",
                                   "  timeBackup = localData->timeValue;\n",
                                   "  localData->states = x;\n",
                                   "\n",
                                   "  for (i=0; i<localData->nStates; i++) {\n",
                                   "    temp_xd[i] = localData->statesDerivatives[i];\n",
                                   "  }\n",
                                   "\n",
                                   "  localData->statesDerivatives = temp_xd;\n",
                                   "  localData->timeValue = *t;\n",
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
  input list<DAELow.ZeroCrossing> i_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_zeroCrossingsCode;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_zeroCrossingsCode, i_varDecls) := zeroCrossingsTpl(emptyTxt, i_zeroCrossings, i_varDecls);
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
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "functionODE();\n",
                                       "functionDAE_output();\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_zeroCrossingsCode);
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

protected function lm_75
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(name = _)) :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("save("));
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_75(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_75(txt, rest);
      then txt;
  end matchcontinue;
end lm_75;

protected function lm_76
  input Tpl.Text in_txt;
  input list<list<SimCode.SimVar>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_vars :: rest )
      local
        list<list<SimCode.SimVar>> rest;
        list<SimCode.SimVar> i_vars;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(":\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_75(txt, i_vars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_76(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<list<SimCode.SimVar>> rest;
      equation
        txt = lm_76(txt, rest);
      then txt;
  end matchcontinue;
end lm_76;

public function functionHandleZeroCrossing
  input Tpl.Text txt;
  input list<list<SimCode.SimVar>> i_zeroCrossingsNeedSave;

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
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_76(out_txt, i_zeroCrossingsNeedSave);
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
  input list<DAELow.ZeroCrossing> i_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_timeEventCode;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_timeEventCode, i_varDecls) := timeEventsTpl(emptyTxt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* Initializes the raw time events of the simulation using the now\n",
                                   "   calcualted parameters. */\n",
                                   "void function_sampleInit()\n",
                                   "{\n",
                                   "  int i = 0; // Current index\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_timeEventCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitSample;

protected function lm_79
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_79(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_79(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_79;

protected function lm_80
  input Tpl.Text in_txt;
  input list<SimCode.HelpVarInfo> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_hindex, i_exp, _) :: rest,
           i_varDecls )
      local
        list<SimCode.HelpVarInfo> rest;
        DAE.Exp i_exp;
        Integer i_hindex;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hindex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_80(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.HelpVarInfo> rest;
      equation
        (txt, i_varDecls) = lm_80(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_80;

public function functionUpdateDependents
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_allEquations;
  input list<SimCode.HelpVarInfo> i_helpVarInfo;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_hvars;
  Tpl.Text i_eqs;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_eqs := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_eqs, i_varDecls) := lm_79(i_eqs, i_allEquations, i_varDecls);
  i_eqs := Tpl.popIter(i_eqs);
  i_hvars := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_hvars, i_varDecls) := lm_80(i_hvars, i_helpVarInfo, i_varDecls);
  i_hvars := Tpl.popIter(i_hvars);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_updateDependents()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "inUpdate=initial()?0:1;\n",
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_eqs);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_hvars);
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

protected function lm_82
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_82(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_82(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_82;

public function functionUpdateDepend
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_allEquationsPlusWhen;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_eqs;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_eqs := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_eqs, i_varDecls) := lm_82(i_eqs, i_allEquationsPlusWhen, i_varDecls);
  i_eqs := Tpl.popIter(i_eqs);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_updateDepend()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "inUpdate=initial()?0:1;\n",
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_eqs);
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
end functionUpdateDepend;

public function functionOnlyZeroCrossing
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_zeroCrossingsCode;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_zeroCrossingsCode, i_varDecls) := zeroCrossingsTpl(emptyTxt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_onlyZeroCrossings(double *gout,double *t)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_zeroCrossingsCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionOnlyZeroCrossing;

protected function lm_85
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_var;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (change("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) { needToIterate=1; }"));
        txt = Tpl.nextIter(txt);
        txt = lm_85(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_85(txt, rest);
      then txt;
  end matchcontinue;
end lm_85;

public function functionCheckForDiscreteChanges
  input Tpl.Text txt;
  input list<DAE.ComponentRef> i_discreteModelVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int checkForDiscreteChanges()\n",
                                   "{\n",
                                   "  int needToIterate = 0;\n",
                                   "\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_85(out_txt, i_discreteModelVars);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "return needToIterate;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionCheckForDiscreteChanges;

protected function lm_87
  input Tpl.Text in_txt;
  input list<tuple<Integer, DAE.Exp>> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_id, i_e) :: rest,
           i_varDecls )
      local
        list<tuple<Integer, DAE.Exp>> rest;
        DAE.Exp i_e;
        Integer i_id;
        Tpl.Text i_eRes;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_eRes, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, SimCode.contextSimulationNonDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("storeDelayedExpression("));
        txt = Tpl.writeStr(txt, intString(i_id));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_eRes);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        (txt, i_varDecls) = lm_87(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<tuple<Integer, DAE.Exp>> rest;
      equation
        (txt, i_varDecls) = lm_87(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_87;

protected function fun_88
  input Tpl.Text in_txt;
  input SimCode.DelayedExpression in_i_delayed;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_delayed, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.DELAYED_EXPRESSIONS(delayedExps = i_delayedExps),
           i_varDecls )
      local
        list<tuple<Integer, DAE.Exp>> i_delayedExps;
      equation
        (txt, i_varDecls) = lm_87(txt, i_delayedExps, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_88;

protected function fun_89
  input Tpl.Text in_txt;
  input SimCode.DelayedExpression in_i_delayed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_delayed)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.DELAYED_EXPRESSIONS(maxDelayedIndex = i_maxDelayedIndex) )
      local
        Integer i_maxDelayedIndex;
      equation
        txt = Tpl.writeStr(txt, intString(i_maxDelayedIndex));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_89;

public function functionStoreDelayed
  input Tpl.Text txt;
  input SimCode.DelayedExpression i_delayed;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_storePart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  (i_storePart, i_varDecls) := fun_88(emptyTxt, i_delayed, i_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("int numDelayExpressionIndex = "));
  out_txt := fun_89(out_txt, i_delayed);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "int function_storeDelayed()\n",
                                       "{\n",
                                       "  state mem_state;\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_storePart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionStoreDelayed;

protected function lm_91
  input Tpl.Text in_txt;
  input list<DAELow.ReinitStatement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_reinit :: rest,
           i_varDecls )
      local
        list<DAELow.ReinitStatement> rest;
        DAELow.ReinitStatement i_reinit;
        Tpl.Text i_body;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_body, i_preExp, i_varDecls) = functionWhenReinitStatement(emptyTxt, i_reinit, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_91(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAELow.ReinitStatement> rest;
      equation
        (txt, i_varDecls) = lm_91(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_91;

protected function lm_92
  input Tpl.Text in_txt;
  input list<SimCode.SimWhenClause> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIM_WHEN_CLAUSE(whenEq = i_whenEq, reinits = i_reinits) :: rest,
           i_varDecls )
      local
        list<SimCode.SimWhenClause> rest;
        list<DAELow.ReinitStatement> i_reinits;
        Option<DAELow.WhenEquation> i_whenEq;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(":\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        (txt, i_varDecls) = functionWhenCaseEquation(txt, i_whenEq, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_91(txt, i_reinits, i_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_92(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimWhenClause> rest;
      equation
        (txt, i_varDecls) = lm_92(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_92;

public function functionWhen
  input Tpl.Text txt;
  input list<SimCode.SimWhenClause> i_whenClauses;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_cases;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_cases := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, NONE, 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_cases, i_varDecls) := lm_92(i_cases, i_whenClauses, i_varDecls);
  i_cases := Tpl.popIter(i_cases);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_when(int i)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n",
                                       "\n",
                                       "switch(i) {\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_cases);
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
  input Option<DAELow.WhenEquation> in_i_when;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_when, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME((i_weq as DAELow.WHEN_EQ(right = i_weq_right, left = i_weq_left))),
           i_varDecls )
      local
        DAE.ComponentRef i_weq_left;
        DAE.Exp i_weq_right;
        DAELow.WhenEquation i_weq;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_weq_right, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("save("));
        txt = cref(txt, i_weq_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_weq_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end functionWhenCaseEquation;

public function functionWhenReinitStatement
  input Tpl.Text in_txt;
  input DAELow.ReinitStatement in_i_reinit;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_reinit, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAELow.REINIT(value = i_value, stateVar = i_stateVar),
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_stateVar;
        DAE.Exp i_value;
        Tpl.Text i_val;
      equation
        (i_val, i_preExp, i_varDecls) = daeExp(emptyTxt, i_value, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_val);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end functionWhenReinitStatement;

protected function lm_96
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_eq :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_96(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_96(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_96;

public function functionOde
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_stateContEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_stateContPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_stateContPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_stateContPart, i_varDecls) := lm_96(i_stateContPart, i_stateContEquations, i_varDecls);
  i_stateContPart := Tpl.popIter(i_stateContPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionODE()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_stateContPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionOde;

protected function lm_98
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_98(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_98(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_98;

protected function lm_99
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(cref = i_cref) :: rest )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.Exp i_cref;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (sim_verbose) { printf(\"Setting variable start value: %s(start=%f)\\n\", \""));
        txt = expCref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\", "));
        txt = expCref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("); }"));
        txt = Tpl.nextIter(txt);
        txt = lm_99(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        txt = lm_99(txt, rest);
      then txt;
  end matchcontinue;
end lm_99;

public function functionInitial
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_initialEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_eqPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_eqPart := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_eqPart, i_varDecls) := lm_98(i_eqPart, i_initialEquations, i_varDecls);
  i_eqPart := Tpl.popIter(i_eqPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int initial_function()\n",
                                   "{\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(out_txt, i_eqPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_99(out_txt, i_initialEquations);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitial;

protected function fun_101
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.SCONST(string = _),
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->initialResiduals[i++] = 0;"));
      then (txt, i_varDecls);

    case ( txt,
           i_exp,
           i_varDecls )
      local
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->initialResiduals[i++] = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_101;

protected function lm_102
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SES_RESIDUAL(exp = i_exp) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_varDecls) = fun_101(txt, i_exp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_102(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_102(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_102;

public function functionInitialResidual
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_residualEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_body;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_body := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_body, i_varDecls) := lm_102(i_body, i_residualEquations, i_varDecls);
  i_body := Tpl.popIter(i_body);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int initial_residual()\n",
                                   "{\n",
                                   "  int i = 0;\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitialResidual;

protected function lm_104
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq2 as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq2;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq2, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_104(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_104(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_104;

protected function lm_105
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq2 as SimCode.SES_RESIDUAL(exp = i_eq2_exp)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.Exp i_eq2_exp;
        SimCode.SimEqSystem i_eq2;
        Integer i_i0;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_eq2_exp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("res["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_105(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_105(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_105;

protected function lm_106
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_eq as SimCode.SES_NONLINEAR(eqs = i_eq_eqs, index = i_index)) :: rest )
      local
        list<SimCode.SimEqSystem> rest;
        Integer i_index;
        list<SimCode.SimEqSystem> i_eq_eqs;
        SimCode.SimEqSystem i_eq;
        Tpl.Text i_body;
        Tpl.Text i_prebody;
        Tpl.Text i_varDecls;
      equation
        i_varDecls = emptyTxt;
        i_prebody = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_prebody, i_varDecls) = lm_104(i_prebody, i_eq_eqs, i_varDecls);
        i_prebody = Tpl.popIter(i_prebody);
        i_body = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_body, i_varDecls) = lm_105(i_body, i_eq_eqs, i_varDecls);
        i_body = Tpl.popIter(i_body);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void residualFunc"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(int *n, double* xloc, double* res, int* iflag)\n",
                                    "{\n",
                                    "  state mem_state;\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("mem_state = get_memory_state();\n"));
        txt = Tpl.writeText(txt, i_prebody);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("restore_memory_state(mem_state);\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
        txt = Tpl.nextIter(txt);
        txt = lm_106(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        txt = lm_106(txt, rest);
      then txt;
  end matchcontinue;
end lm_106;

public function functionExtraResiduals
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_allEquations;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING_LIST({
                                                                  "\n",
                                                                  "\n"
                                                              }, true)), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_106(out_txt, i_allEquations);
  out_txt := Tpl.popIter(out_txt);
end functionExtraResiduals;

protected function lm_108
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_108(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_108(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_108;

protected function lm_109
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_ALGORITHM(statements = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_109(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls) = lm_109(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_109;

public function functionBoundParameters
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_parameterEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_divbody;
  Tpl.Text i_body;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := emptyTxt;
  i_body := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_body, i_varDecls) := lm_108(i_body, i_parameterEquations, i_varDecls);
  i_body := Tpl.popIter(i_body);
  i_divbody := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_divbody, i_varDecls) := lm_109(i_divbody, i_parameterEquations, i_varDecls);
  i_divbody := Tpl.popIter(i_divbody);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int bound_parameters()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_divbody);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionBoundParameters;

protected function fun_111
  input Tpl.Text in_txt;
  input Integer in_i_windex;
  input Integer in_i_hindex;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_windex, in_i_hindex)
    local
      Tpl.Text txt;
      Integer i_hindex;

    case ( txt,
           -1,
           _ )
      then txt;

    case ( txt,
           i_windex,
           i_hindex )
      local
        Integer i_windex;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hindex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])) AddEvent("));
        txt = Tpl.writeStr(txt, intString(i_windex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" + localData->nZeroCrossing);"));
      then txt;
  end matchcontinue;
end fun_111;

protected function lm_112
  input Tpl.Text in_txt;
  input list<SimCode.HelpVarInfo> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_hindex, i_exp, i_windex) :: rest )
      local
        list<SimCode.HelpVarInfo> rest;
        Integer i_windex;
        DAE.Exp i_exp;
        Integer i_hindex;
      equation
        txt = fun_111(txt, i_windex, i_hindex);
        txt = Tpl.nextIter(txt);
        txt = lm_112(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.HelpVarInfo> rest;
      equation
        txt = lm_112(txt, rest);
      then txt;
  end matchcontinue;
end lm_112;

protected function lm_113
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_var;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (change("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) { needToIterate=1; }"));
        txt = Tpl.nextIter(txt);
        txt = lm_113(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_113(txt, rest);
      then txt;
  end matchcontinue;
end lm_113;

public function functionCheckForDiscreteVarChanges
  input Tpl.Text txt;
  input list<SimCode.HelpVarInfo> i_helpVarInfo;
  input list<DAE.ComponentRef> i_discreteModelVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int checkForDiscreteVarChanges()\n",
                                   "{\n",
                                   "  int needToIterate = 0;\n",
                                   "\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_112(out_txt, i_helpVarInfo);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_113(out_txt, i_discreteModelVars);
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

protected function lm_115
  input Tpl.Text in_txt;
  input list<DAELow.ZeroCrossing> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAELow.ZERO_CROSSING(relation_ = i_relation__) :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
        DAE.Exp i_relation__;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        (txt, i_varDecls) = zeroCrossingTpl(txt, i_i0, i_relation__, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_115(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
      equation
        (txt, i_varDecls) = lm_115(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_115;

public function zeroCrossingsTpl
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_i_varDecls) := lm_115(out_txt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.popIter(out_txt);
end zeroCrossingsTpl;

protected function fun_117
  input Tpl.Text in_txt;
  input DAE.Exp in_i_relation;
  input Integer in_i_index;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_relation, in_i_index, in_i_varDecls)
    local
      Tpl.Text txt;
      Integer i_index;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.RELATION(exp1 = i_exp1, operator = i_operator, exp2 = i_exp2),
           i_index,
           i_varDecls )
      local
        DAE.Exp i_exp2;
        DAE.Operator i_operator;
        DAE.Exp i_exp1;
        Tpl.Text i_e2;
        Tpl.Text i_op;
        Tpl.Text i_e1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, SimCode.contextOther, i_preExp, i_varDecls);
        i_op = zeroCrossingOpFunc(emptyTxt, i_operator);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp2, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZEROCROSSING("));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_op);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval}),
           i_index,
           i_varDecls )
      local
        DAE.Exp i_interval;
        DAE.Exp i_start;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_start, SimCode.contextOther, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_interval, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZEROCROSSING("));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",Sample(*t,"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZERO CROSSING ERROR"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_117;

public function zeroCrossingTpl
  input Tpl.Text txt;
  input Integer i_index;
  input DAE.Exp i_relation;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_117(txt, i_relation, i_index, i_varDecls);
end zeroCrossingTpl;

protected function lm_119
  input Tpl.Text in_txt;
  input list<DAELow.ZeroCrossing> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAELow.ZERO_CROSSING(relation_ = i_relation__) :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
        DAE.Exp i_relation__;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        (txt, i_varDecls) = timeEventTpl(txt, i_i0, i_relation__, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_119(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAELow.ZeroCrossing> rest;
      equation
        (txt, i_varDecls) = lm_119(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_119;

public function timeEventsTpl
  input Tpl.Text txt;
  input list<DAELow.ZeroCrossing> i_zeroCrossings;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_i_varDecls) := lm_119(out_txt, i_zeroCrossings, i_varDecls);
  out_txt := Tpl.popIter(out_txt);
end timeEventsTpl;

protected function fun_121
  input Tpl.Text in_txt;
  input DAE.Exp in_i_relation;
  input Integer in_i_index;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_relation, in_i_index, in_i_varDecls)
    local
      Tpl.Text txt;
      Integer i_index;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.RELATION(exp1 = _),
           i_index,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* "));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" Not a time event */"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval}),
           i_index,
           i_varDecls )
      local
        DAE.Exp i_interval;
        DAE.Exp i_start;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_start, SimCode.contextOther, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_interval, SimCode.contextOther, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->rawSampleExps[i].start = "));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "localData->rawSampleExps[i].interval = "
                                }, false));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "localData->rawSampleExps[i++].zc_index = "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZERO CROSSING ERROR"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_121;

public function timeEventTpl
  input Tpl.Text txt;
  input Integer i_index;
  input DAE.Exp i_relation;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_121(txt, i_relation, i_index, i_varDecls);
end timeEventTpl;

public function zeroCrossingOpFunc
  input Tpl.Text in_txt;
  input DAE.Operator in_i_op;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_op)
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
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_e as SimCode.SES_SIMPLE_ASSIGN(cref = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationSimpleAssign(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_ARRAY_CALL_ASSIGN(componentRef = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationArrayCallAssign(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_ALGORITHM(statements = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationAlgorithm(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_LINEAR(partOfMixed = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationLinear(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_MIXED(cont = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationMixed(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_NONLINEAR(index = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationNonlinear(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_e as SimCode.SES_WHEN(left = _)),
           i_context,
           i_varDecls )
      local
        SimCode.SimEqSystem i_e;
      equation
        (txt, i_varDecls) = equationWhen(txt, i_e, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED EQUATION"));
      then (txt, i_varDecls);
  end matchcontinue;
end equation_;

public function equationSimpleAssign
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(exp = i_exp, cref = i_cref),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_cref;
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = expCref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationSimpleAssign;

public function equationArrayCallAssign
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_ARRAY_CALL_ASSIGN(exp = i_exp, componentRef = i_componentRef),
           i_context,
           i_varDecls )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_real_array_data_mem(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = cref(txt, i_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationArrayCallAssign;

protected function lm_127
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_127(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_127(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_127;

public function equationAlgorithm
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_ALGORITHM(statements = i_statements),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_statements;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_127(txt, i_statements, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationAlgorithm;

protected function fun_129
  input Tpl.Text in_txt;
  input Boolean in_i_partOfMixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_partOfMixed)
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
end fun_129;

protected function lm_130
  input Tpl.Text in_txt;
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> in_items;
  input Tpl.Text in_i_size;
  input Tpl.Text in_i_aname;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_size, in_i_aname, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_size;
      Tpl.Text i_aname;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           _,
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           (i_row, i_col, (i_eq as SimCode.SES_RESIDUAL(exp = i_eq_exp))) :: rest,
           i_size,
           i_aname,
           i_varDecls,
           i_context )
      local
        list<tuple<Integer, Integer, SimCode.SimEqSystem>> rest;
        DAE.Exp i_eq_exp;
        SimCode.SimEqSystem i_eq;
        Integer i_col;
        Integer i_row;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_eq_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("set_matrix_elt("));
        txt = Tpl.writeText(txt, i_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_130(txt, rest, i_size, i_aname, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_size,
           i_aname,
           i_varDecls,
           i_context )
      local
        list<tuple<Integer, Integer, SimCode.SimEqSystem>> rest;
      equation
        (txt, i_varDecls) = lm_130(txt, rest, i_size, i_aname, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_130;

protected function lm_131
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_bname;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_bname, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_bname;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_exp :: rest,
           i_bname,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
        Integer i_i0;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("set_vector_elt("));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_131(txt, rest, i_bname, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_bname,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls) = lm_131(txt, rest, i_bname, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_131;

protected function lm_132
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;
  input Tpl.Text in_i_bname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_bname)
    local
      Tpl.Text txt;
      Tpl.Text i_bname;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           (i_s as SimCode.SIMVAR(name = _)) :: rest,
           i_bname )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_s;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = simVarStr(txt, i_s);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_vector_elt("));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_132(txt, rest, i_bname);
      then txt;

    case ( txt,
           _ :: rest,
           i_bname )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_132(txt, rest, i_bname);
      then txt;
  end matchcontinue;
end lm_132;

public function equationLinear
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_LINEAR(vars = i_vars, partOfMixed = i_partOfMixed, simJac = i_simJac, beqs = i_beqs),
           i_context,
           i_varDecls )
      local
        list<DAE.Exp> i_beqs;
        list<tuple<Integer, Integer, SimCode.SimEqSystem>> i_simJac;
        Boolean i_partOfMixed;
        list<SimCode.SimVar> i_vars;
        Tpl.Text i_mixedPostfix;
        Tpl.Text i_bname;
        Tpl.Text i_aname;
        Integer ret_3;
        Tpl.Text i_size;
        Integer ret_1;
        Tpl.Text i_uid;
      equation
        ret_1 = System.tmpTick();
        i_uid = Tpl.writeStr(emptyTxt, intString(ret_1));
        ret_3 = listLength(i_vars);
        i_size = Tpl.writeStr(emptyTxt, intString(ret_3));
        i_aname = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("A"));
        i_aname = Tpl.writeText(i_aname, i_uid);
        i_bname = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("b"));
        i_bname = Tpl.writeText(i_bname, i_uid);
        i_mixedPostfix = fun_129(emptyTxt, i_partOfMixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("declare_matrix("));
        txt = Tpl.writeText(txt, i_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "declare_vector("
                                }, false));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_130(txt, i_simJac, i_size, i_aname, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_131(txt, i_beqs, i_bname, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("solve_linear_equation_system"));
        txt = Tpl.writeText(txt, i_mixedPostfix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_uid);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_132(txt, i_vars, i_bname);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationLinear;

protected function lm_134
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preDisc;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preDisc;
algorithm
  (out_txt, out_i_varDecls, out_i_preDisc) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preDisc, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preDisc;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preDisc,
           _ )
      then (txt, i_varDecls, i_preDisc);

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(exp = i_exp, cref = i_cref) :: rest,
           i_varDecls,
           i_preDisc,
           i_context )
      local
        list<SimCode.SimEqSystem> rest;
        DAE.Exp i_cref;
        DAE.Exp i_exp;
        Integer i_i0;
        Tpl.Text i_expPart;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        (i_expPart, i_preDisc, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preDisc, i_varDecls);
        txt = expCref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "discrete_loc2["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = expCref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preDisc) = lm_134(txt, rest, i_varDecls, i_preDisc, i_context);
      then (txt, i_varDecls, i_preDisc);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preDisc,
           i_context )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        (txt, i_varDecls, i_preDisc) = lm_134(txt, rest, i_varDecls, i_preDisc, i_context);
      then (txt, i_varDecls, i_preDisc);
  end matchcontinue;
end lm_134;

protected function lm_135
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_val :: rest )
      local
        list<String> rest;
        String i_val;
      equation
        txt = Tpl.writeStr(txt, i_val);
        txt = Tpl.nextIter(txt);
        txt = lm_135(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_135(txt, rest);
      then txt;
  end matchcontinue;
end lm_135;

protected function lm_136
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      local
        list<Integer> rest;
        Integer i_dim;
      equation
        txt = Tpl.writeStr(txt, intString(i_dim));
        txt = Tpl.nextIter(txt);
        txt = lm_136(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_136(txt, rest);
      then txt;
  end matchcontinue;
end lm_136;

protected function lm_137
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.SIMVAR(name = _)) :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("discrete_loc["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = simVarStr(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_137(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_137(txt, rest);
      then txt;
  end matchcontinue;
end lm_137;

protected function lm_138
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.SIMVAR(name = _)) :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = simVarStr(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_138(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_138(txt, rest);
      then txt;
  end matchcontinue;
end lm_138;

public function equationMixed
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_MIXED(cont = i_cont, discVars = i_discVars, values = i_values, discEqs = i_discEqs, value_dims = i_value__dims),
           i_context,
           i_varDecls )
      local
        list<Integer> i_value__dims;
        list<SimCode.SimEqSystem> i_discEqs;
        list<String> i_values;
        list<SimCode.SimVar> i_discVars;
        SimCode.SimEqSystem i_cont;
        Tpl.Text i_discLoc2;
        Tpl.Text i_preDisc;
        Integer ret_4;
        Tpl.Text i_valuesLenStr;
        Integer ret_2;
        Tpl.Text i_numDiscVarsStr;
        Tpl.Text i_contEqs;
      equation
        (i_contEqs, i_varDecls) = equation_(emptyTxt, i_cont, i_context, i_varDecls);
        ret_2 = listLength(i_discVars);
        i_numDiscVarsStr = Tpl.writeStr(emptyTxt, intString(ret_2));
        ret_4 = listLength(i_values);
        i_valuesLenStr = Tpl.writeStr(emptyTxt, intString(ret_4));
        i_preDisc = emptyTxt;
        i_discLoc2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_discLoc2, i_varDecls, i_preDisc) = lm_134(i_discLoc2, i_discEqs, i_varDecls, i_preDisc, i_context);
        i_discLoc2 = Tpl.popIter(i_discLoc2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mixed_equation_system("));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "double values["
                                }, false));
        txt = Tpl.writeText(txt, i_valuesLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_135(txt, i_values);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "int value_dims["
                                }, false));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_136(txt, i_value__dims);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("};\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_137(txt, i_discVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("{\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_contEqs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, i_preDisc);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_discLoc2);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("{\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("double *loc_ptrs["));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_138(txt, i_discVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "check_discrete_values("
                                }, false));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_valuesLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "mixed_equation_system_end("
                                }, false));
        txt = Tpl.writeText(txt, i_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationMixed;

protected function lm_140
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("nls_x["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = extraPolate("));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "nls_xold["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = old(&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_140(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_140(txt, rest);
      then txt;
  end matchcontinue;
end lm_140;

protected function lm_141
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      local
        list<DAE.ComponentRef> rest;
        DAE.ComponentRef i_name;
        Integer i_i0;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = nls_x["));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_141(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.ComponentRef> rest;
      equation
        txt = lm_141(txt, rest);
      then txt;
  end matchcontinue;
end lm_141;

protected function fun_142
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_eq)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SES_NONLINEAR(crefs = i_crefs, index = i_index) )
      local
        Integer i_index;
        list<DAE.ComponentRef> i_crefs;
        Integer ret_1;
        Tpl.Text i_size;
      equation
        ret_1 = listLength(i_crefs);
        i_size = Tpl.writeStr(emptyTxt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("start_nonlinear_system("));
        txt = Tpl.writeText(txt, i_size);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_140(txt, i_crefs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("solve_nonlinear_system(residualFunc"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_141(txt, i_crefs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("end_nonlinear_system();"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_142;

public function equationNonlinear
  input Tpl.Text txt;
  input SimCode.SimEqSystem i_eq;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := fun_142(txt, i_eq);
  out_i_varDecls := i_varDecls;
end equationNonlinear;

protected function lm_144
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Integer>> in_items;
  input Tpl.Text in_i_helpInits;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_helpInits;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_helpInits, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_helpInits, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_helpInits;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_helpInits,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_helpInits, i_varDecls, i_preExp);

    case ( txt,
           (i_e, i_hidx) :: rest,
           i_helpInits,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Integer>> rest;
        Integer i_hidx;
        DAE.Exp i_e;
        Tpl.Text i_helpInit;
      equation
        (i_helpInit, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING("localData->helpVars["));
        i_helpInits = Tpl.writeStr(i_helpInits, intString(i_hidx));
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING("] = "));
        i_helpInits = Tpl.writeText(i_helpInits, i_helpInit);
        i_helpInits = Tpl.writeTok(i_helpInits, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hidx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        (txt, i_helpInits, i_varDecls, i_preExp) = lm_144(txt, rest, i_helpInits, i_varDecls, i_preExp, i_context);
      then (txt, i_helpInits, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_helpInits,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Integer>> rest;
      equation
        (txt, i_helpInits, i_varDecls, i_preExp) = lm_144(txt, rest, i_helpInits, i_varDecls, i_preExp, i_context);
      then (txt, i_helpInits, i_varDecls, i_preExp);
  end matchcontinue;
end lm_144;

public function equationWhen
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_i_eq;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_eq, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SES_WHEN(conditions = i_conditions, right = i_right, left = i_left),
           i_context,
           i_varDecls )
      local
        DAE.ComponentRef i_left;
        DAE.Exp i_right;
        list<tuple<DAE.Exp, Integer>> i_conditions;
        Tpl.Text i_exp;
        Tpl.Text i_preExp2;
        Tpl.Text i_helpIf;
        Tpl.Text i_helpInits;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        i_helpInits = emptyTxt;
        i_helpIf = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_helpIf, i_helpInits, i_varDecls, i_preExp) = lm_144(i_helpIf, i_conditions, i_helpInits, i_varDecls, i_preExp, i_context);
        i_helpIf = Tpl.popIter(i_helpIf);
        i_preExp2 = emptyTxt;
        (i_exp, i_preExp2, i_varDecls) = daeExp(emptyTxt, i_right, i_context, i_preExp2, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_helpInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, i_helpIf);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp2);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_exp);
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
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end equationWhen;

public function simulationFunctionsFile
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "#ifdef __cplusplus\n",
                                   "extern \"C\" {\n",
                                   "#endif\n",
                                   "\n",
                                   "/* Header */\n"
                               }, true));
  out_txt := externalFunctionIncludes(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeaders(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Header */\n",
                                       "\n",
                                       "/* Body */\n"
                                   }, true));
  out_txt := functionBodies(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Body */\n",
                                       "\n",
                                       "#ifdef __cplusplus\n",
                                       "}\n",
                                       "#endif"
                                   }, false));
end simulationFunctionsFile;

protected function fun_147
  input Tpl.Text in_txt;
  input String in_i_modelInfo_directory;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo_directory)
    local
      Tpl.Text txt;

    case ( txt,
           "" )
      then txt;

    case ( txt,
           i_modelInfo_directory )
      local
        String i_modelInfo_directory;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-L\""));
        txt = Tpl.writeStr(txt, i_modelInfo_directory);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;
  end matchcontinue;
end fun_147;

protected function lm_148
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_lib :: rest )
      local
        list<String> rest;
        String i_lib;
      equation
        txt = Tpl.writeStr(txt, i_lib);
        txt = Tpl.nextIter(txt);
        txt = lm_148(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_148(txt, rest);
      then txt;
  end matchcontinue;
end lm_148;

protected function fun_149
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_libsStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_libsStr)
    local
      Tpl.Text txt;
      Tpl.Text i_libsStr;

    case ( txt,
           "",
           i_libsStr )
      equation
        txt = Tpl.writeText(txt, i_libsStr);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_149;

protected function fun_150
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_libsStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_libsStr)
    local
      Tpl.Text txt;
      Tpl.Text i_libsStr;

    case ( txt,
           "",
           _ )
      then txt;

    case ( txt,
           _,
           i_libsStr )
      equation
        txt = Tpl.writeText(txt, i_libsStr);
      then txt;
  end matchcontinue;
end fun_150;

public function simulationMakefile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(directory = i_modelInfo_directory, name = i_modelInfo_name), makefileParams = SimCode.MAKEFILE_PARAMS(libs = i_makefileParams_libs, ccompiler = i_makefileParams_ccompiler, cxxcompiler = i_makefileParams_cxxcompiler, linker = i_makefileParams_linker, exeext = i_makefileParams_exeext, dllext = i_makefileParams_dllext, omhome = i_makefileParams_omhome, cflags = i_makefileParams_cflags, ldflags = i_makefileParams_ldflags, senddatalibs = i_makefileParams_senddatalibs)) )
      local
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
        String i_modelInfo_name;
        String i_modelInfo_directory;
        String str_5;
        Tpl.Text i_libsPos2;
        String str_3;
        Tpl.Text i_libsPos1;
        Tpl.Text i_libsStr;
        Tpl.Text i_dirExtra;
      equation
        i_dirExtra = fun_147(emptyTxt, i_modelInfo_directory);
        i_libsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_libsStr = lm_148(i_libsStr, i_makefileParams_libs);
        i_libsStr = Tpl.popIter(i_libsStr);
        str_3 = Tpl.textString(i_dirExtra);
        i_libsPos1 = fun_149(emptyTxt, str_3, i_libsStr);
        str_5 = Tpl.textString(i_dirExtra);
        i_libsPos2 = fun_150(emptyTxt, str_5, i_libsStr);
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
        txt = Tpl.writeStr(txt, i_modelInfo_name);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeStr(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(": "));
        txt = Tpl.writeStr(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(".cpp\n"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\t"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(CXX) $(CFLAGS) -I. -o "));
        txt = Tpl.writeStr(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$(EXEEXT) "));
        txt = Tpl.writeStr(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".cpp "));
        txt = Tpl.writeText(txt, i_dirExtra);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_libsPos1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" -lsim $(LDFLAGS) -lf2c -linteractive $(SENDDATALIBS) "));
        txt = Tpl.writeText(txt, i_libsPos2);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationMakefile;

protected function lm_152
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_152(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_152(txt, rest);
      then txt;
  end matchcontinue;
end lm_152;

public function functionsFile
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;
  input list<SimCode.RecordDeclaration> i_extraRecordDecls;

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
                                   "#endif\n",
                                   "\n",
                                   "#if !defined(MODELICA_ASSERT)\n",
                                   "  #define MODELICA_ASSERT(cond,msg) { if (!(cond)) fprintf(stderr,\"Modelica Assert: %s!\\n\", msg); }\n",
                                   "#endif\n",
                                   "#if !defined(MODELICA_TERMINATE)\n",
                                   "  #define MODELICA_TERMINATE(msg) { fprintf(stderr,\"Modelica Terminate: %s!\\n\", msg); fflush(stderr); }\n",
                                   "#endif\n",
                                   "\n",
                                   "#ifdef __cplusplus\n",
                                   "extern \"C\" {\n",
                                   "#endif\n",
                                   "\n",
                                   "/* Header */\n"
                               }, true));
  out_txt := externalFunctionIncludes(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeaders(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_152(out_txt, i_extraRecordDecls);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Header */\n",
                                       "\n",
                                       "/* Body */\n"
                                   }, true));
  out_txt := functionBodies(out_txt, i_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "/* End Body */\n",
                                       "\n",
                                       "#ifdef __cplusplus\n",
                                       "}\n",
                                       "#endif"
                                   }, false));
end functionsFile;

protected function lm_154
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_lib :: rest )
      local
        list<String> rest;
        String i_lib;
      equation
        txt = Tpl.writeStr(txt, i_lib);
        txt = Tpl.nextIter(txt);
        txt = lm_154(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_154(txt, rest);
      then txt;
  end matchcontinue;
end lm_154;

public function functionsMakefile
  input Tpl.Text in_txt;
  input SimCode.FunctionCode in_i_fnCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fnCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.FUNCTIONCODE(makefileParams = SimCode.MAKEFILE_PARAMS(libs = i_makefileParams_libs, ccompiler = i_makefileParams_ccompiler, cxxcompiler = i_makefileParams_cxxcompiler, linker = i_makefileParams_linker, exeext = i_makefileParams_exeext, dllext = i_makefileParams_dllext, omhome = i_makefileParams_omhome, cflags = i_makefileParams_cflags, ldflags = i_makefileParams_ldflags), name = i_name) )
      local
        String i_name;
        String i_makefileParams_ldflags;
        String i_makefileParams_cflags;
        String i_makefileParams_omhome;
        String i_makefileParams_dllext;
        String i_makefileParams_exeext;
        String i_makefileParams_linker;
        String i_makefileParams_cxxcompiler;
        String i_makefileParams_ccompiler;
        list<String> i_makefileParams_libs;
        Tpl.Text i_libsStr;
      equation
        i_libsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_libsStr = lm_154(i_libsStr, i_makefileParams_libs);
        i_libsStr = Tpl.popIter(i_libsStr);
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
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    ".PHONY: "
                                }, false));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(": "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(".c\n"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\t"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(LINK) $(CFLAGS) -o "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$(DLLEXT) "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".c "));
        txt = Tpl.writeText(txt, i_libsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(LDFLAGS) -lm"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionsMakefile;

protected function fun_156
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_cr )
      equation
        txt = crefStr(txt, i_cr);
      then txt;

    case ( txt,
           _,
           i_cr )
      equation
        txt = cref(txt, i_cr);
      then txt;
  end matchcontinue;
end fun_156;

public function contextCref
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;
  input SimCode.Context i_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_156(txt, i_context, i_cr);
end contextCref;

protected function fun_158
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Absyn.Ident in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_name)
    local
      Tpl.Text txt;
      Absyn.Ident i_name;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_name )
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _,
           i_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$"));
        txt = Tpl.writeStr(txt, i_name);
      then txt;
  end matchcontinue;
end fun_158;

public function contextIteratorName
  input Tpl.Text txt;
  input Absyn.Ident i_name;
  input SimCode.Context i_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_158(txt, i_context, i_name);
end contextIteratorName;

public function cref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref)
    local
      Tpl.Text txt;

    case ( txt,
           (i_cref as DAE.CREF_IDENT(ident = "xloc")) )
      local
        DAE.ComponentRef i_cref;
      equation
        txt = crefStr(txt, i_cref);
      then txt;

    case ( txt,
           DAE.CREF_IDENT(ident = "time") )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("time"));
      then txt;

    case ( txt,
           i_cref )
      local
        DAE.ComponentRef i_cref;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$"));
        txt = crefToCStr(txt, i_cref);
      then txt;
  end matchcontinue;
end cref;

public function crefToCStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      local
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsToCStr(txt, i_subscriptLst);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = "$DER", componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DER$"));
        txt = crefToCStr(txt, i_componentRef);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, subscriptLst = i_subscriptLst, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
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

protected function lm_162
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_s :: rest )
      local
        list<DAE.Subscript> rest;
        DAE.Subscript i_s;
      equation
        txt = subscriptToCStr(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_162(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Subscript> rest;
      equation
        txt = lm_162(txt, rest);
      then txt;
  end matchcontinue;
end lm_162;

public function subscriptsToCStr
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_i_subscripts;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_subscripts)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_subscripts )
      local
        list<DAE.Subscript> i_subscripts;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$lB"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING("$c")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_162(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$rB"));
      then txt;
  end matchcontinue;
end subscriptsToCStr;

protected function fun_164
  input Tpl.Text in_txt;
  input DAE.Subscript in_i_subscript;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_subscript, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_SUBSCRIPT"));
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_164;

public function subscriptToCStr
  input Tpl.Text txt;
  input DAE.Subscript i_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_varDecls;
  Tpl.Text i_preExp;
algorithm
  i_preExp := emptyTxt;
  i_varDecls := emptyTxt;
  (out_txt, i_varDecls, i_preExp) := fun_164(txt, i_subscript, i_varDecls, i_preExp);
end subscriptToCStr;

public function crefStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      local
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsTpl(txt, i_subscriptLst);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = "$DER", componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("der("));
        txt = crefStr(txt, i_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, subscriptLst = i_subscriptLst, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsTpl(txt, i_subscriptLst);
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

protected function fun_167
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           i_cr )
      equation
        txt = arrayCrefStr(txt, i_cr);
      then txt;

    case ( txt,
           _,
           i_cr )
      equation
        txt = arrayCrefCStr(txt, i_cr);
      then txt;
  end matchcontinue;
end fun_167;

public function contextArrayCref
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;
  input SimCode.Context i_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_167(txt, i_context, i_cr);
end contextArrayCref;

public function arrayCrefCStr
  input Tpl.Text txt;
  input DAE.ComponentRef i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("$"));
  out_txt := arrayCrefCStr2(out_txt, i_cref);
end arrayCrefCStr;

public function arrayCrefCStr2
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      local
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
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
  input DAE.ComponentRef in_i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      local
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
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

protected function lm_172
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_s :: rest )
      local
        list<DAE.Subscript> rest;
        DAE.Subscript i_s;
      equation
        txt = subscriptTpl(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_172(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Subscript> rest;
      equation
        txt = lm_172(txt, rest);
      then txt;
  end matchcontinue;
end lm_172;

public function subscriptsTpl
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_i_subscripts;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_subscripts)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_subscripts )
      local
        list<DAE.Subscript> i_subscripts;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_172(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;
  end matchcontinue;
end subscriptsTpl;

protected function fun_174
  input Tpl.Text in_txt;
  input DAE.Subscript in_i_subscript;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_subscript, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           i_varDecls,
           i_preExp )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_SUBSCRIPT"));
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_174;

public function subscriptTpl
  input Tpl.Text txt;
  input DAE.Subscript i_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_varDecls;
  Tpl.Text i_preExp;
algorithm
  i_preExp := emptyTxt;
  i_varDecls := emptyTxt;
  (out_txt, i_varDecls, i_preExp) := fun_174(txt, i_subscript, i_varDecls, i_preExp);
end subscriptTpl;

public function simVarStr
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMVAR(varKind = i_varKind, name = i_name) )
      local
        DAE.ComponentRef i_name;
        DAELow.VarKind i_varKind;
      equation
        txt = varKindStr(txt, i_varKind);
        txt = cref(txt, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simVarStr;

public function varKindStr
  input Tpl.Text in_txt;
  input DAELow.VarKind in_i_varKind;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_varKind)
    local
      Tpl.Text txt;

    case ( txt,
           DAELow.STATE_DER() )
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end varKindStr;

public function expCref
  input Tpl.Text in_txt;
  input DAE.Exp in_i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF(componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
      equation
        txt = cref(txt, i_componentRef);
      then txt;

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {(i_arg as DAE.CREF(componentRef = i_arg_componentRef))}) )
      local
        DAE.ComponentRef i_arg_componentRef;
        DAE.Exp i_arg;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$DER"));
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
  input DAE.ComponentRef in_i_cref;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      local
        DAE.Ident i_ident;
        String ret_0;
      equation
        ret_0 = System.stringReplace(i_ident, "_", "__");
        txt = Tpl.writeStr(txt, ret_0);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
        String ret_0;
      equation
        ret_0 = System.stringReplace(i_ident, "_", "__");
        txt = Tpl.writeStr(txt, ret_0);
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
  input Absyn.Path in_i_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_path)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.QUALIFIED(name = i_name, path = i_path) )
      local
        Absyn.Path i_path;
        Absyn.Ident i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = dotPath(txt, i_path);
      then txt;

    case ( txt,
           Absyn.IDENT(name = i_name) )
      local
        Absyn.Ident i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           Absyn.FULLYQUALIFIED(path = i_path) )
      local
        Absyn.Path i_path;
      equation
        txt = dotPath(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end dotPath;

public function underscorePath
  input Tpl.Text in_txt;
  input Absyn.Path in_i_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_path)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.QUALIFIED(name = i_name, path = i_path) )
      local
        Absyn.Path i_path;
        Absyn.Ident i_name;
        String ret_0;
      equation
        ret_0 = System.stringReplace(i_name, "_", "__");
        txt = Tpl.writeStr(txt, ret_0);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = underscorePath(txt, i_path);
      then txt;

    case ( txt,
           Absyn.IDENT(name = i_name) )
      local
        Absyn.Ident i_name;
        String ret_0;
      equation
        ret_0 = System.stringReplace(i_name, "_", "__");
        txt = Tpl.writeStr(txt, ret_0);
      then txt;

    case ( txt,
           Absyn.FULLYQUALIFIED(path = i_path) )
      local
        Absyn.Path i_path;
      equation
        txt = underscorePath(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end underscorePath;

protected function lm_182
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_include :: rest )
      local
        list<String> rest;
        String i_include;
      equation
        txt = Tpl.writeStr(txt, i_include);
        txt = Tpl.nextIter(txt);
        txt = lm_182(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_182(txt, rest);
      then txt;
  end matchcontinue;
end lm_182;

protected function lm_183
  input Tpl.Text in_txt;
  input list<SimCode.Function> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(includes = i_includes) :: rest )
      local
        list<SimCode.Function> rest;
        list<String> i_includes;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_182(txt, i_includes);
        txt = Tpl.popIter(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_183(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Function> rest;
      equation
        txt = lm_183(txt, rest);
      then txt;
  end matchcontinue;
end lm_183;

public function externalFunctionIncludes
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "#ifdef __cplusplus\n",
                                   "extern \"C\" {\n",
                                   "#endif\n"
                               }, true));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_183(out_txt, i_functions);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "#ifdef __cplusplus\n",
                                       "}\n",
                                       "#endif"
                                   }, false));
end externalFunctionIncludes;

protected function lm_185
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_185(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_185(txt, rest);
      then txt;
  end matchcontinue;
end lm_185;

protected function lm_186
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_186(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_186(txt, rest);
      then txt;
  end matchcontinue;
end lm_186;

protected function lm_187
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_187(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_187(txt, rest);
      then txt;
  end matchcontinue;
end lm_187;

protected function lm_188
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_188(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_188(txt, rest);
      then txt;
  end matchcontinue;
end lm_188;

protected function fun_189
  input Tpl.Text in_txt;
  input Boolean in_it;
  input list<SimCode.Variable> in_i_funArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_funArgs)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_funArgs;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_funArgs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_188(txt, i_funArgs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_189;

protected function fun_190
  input Tpl.Text in_txt;
  input Boolean in_it;
  input Tpl.Text in_i_funArgsBoxedStr;
  input Tpl.Text in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_funArgsBoxedStr, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_funArgsBoxedStr;
      Tpl.Text i_fname;

    case ( txt,
           false,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_funArgsBoxedStr,
           i_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed_s {\n",
                                    "  modelica_metatype targ1;\n",
                                    "} "
                                }, false));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed;\n",
                                    "\n",
                                    "DLLExport\n"
                                }, true));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettypeboxed boxptr_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_funArgsBoxedStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_190;

protected function lm_191
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
        SimCode.RecordDeclaration i_rd;
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_191(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.RecordDeclaration> rest;
      equation
        txt = lm_191(txt, rest);
      then txt;
  end matchcontinue;
end lm_191;

protected function fun_192
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.FUNCTION(recordDecls = i_recordDecls, name = i_name, functionArguments = i_functionArguments, outVars = i_outVars) )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_functionArguments;
        Absyn.Path i_name;
        list<SimCode.RecordDeclaration> i_recordDecls;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_185(txt, i_recordDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt_0 = underscorePath(emptyTxt, i_name);
        txt = functionHeader(txt, Tpl.textString(txt_0), i_functionArguments, i_outVars);
        txt = Tpl.softNewLine(txt);
        txt_1 = underscorePath(emptyTxt, i_name);
        txt = functionHeaderBoxed(txt, Tpl.textString(txt_1), i_functionArguments, i_outVars);
      then txt;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(recordDecls = i_recordDecls, name = i_name, funArgs = i_funArgs, outVars = i_outVars)) )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        list<SimCode.RecordDeclaration> i_recordDecls;
        SimCode.Function i_fn;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_186(txt, i_recordDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt_0 = underscorePath(emptyTxt, i_name);
        txt = functionHeader(txt, Tpl.textString(txt_0), i_funArgs, i_outVars);
        txt = Tpl.softNewLine(txt);
        txt_1 = underscorePath(emptyTxt, i_name);
        txt = functionHeaderBoxed(txt, Tpl.textString(txt_1), i_funArgs, i_outVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = extFunDef(txt, i_fn);
      then txt;

    case ( txt,
           SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs, recordDecls = i_recordDecls) )
      local
        list<SimCode.RecordDeclaration> i_recordDecls;
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        Boolean ret_5;
        Tpl.Text i_boxedHeader;
        Boolean ret_3;
        Tpl.Text i_funArgsBoxedStr;
        Tpl.Text i_funArgsStr;
        Tpl.Text i_fname;
      equation
        i_fname = underscorePath(emptyTxt, i_name);
        i_funArgsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_funArgsStr = lm_187(i_funArgsStr, i_funArgs);
        i_funArgsStr = Tpl.popIter(i_funArgsStr);
        ret_3 = RTOpts.acceptMetaModelicaGrammar();
        i_funArgsBoxedStr = fun_189(emptyTxt, ret_3, i_funArgs);
        ret_5 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedHeader = fun_190(emptyTxt, ret_5, i_funArgsBoxedStr, i_fname);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_191(txt, i_recordDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettype_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("_rettype_s {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" targ1;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettype;\n",
                                    "\n",
                                    "DLLExport\n"
                                }, true));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_funArgsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_boxedHeader);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_192;

protected function lm_193
  input Tpl.Text in_txt;
  input list<SimCode.Function> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_fn :: rest )
      local
        list<SimCode.Function> rest;
        SimCode.Function i_fn;
      equation
        txt = fun_192(txt, i_fn);
        txt = Tpl.nextIter(txt);
        txt = lm_193(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Function> rest;
      equation
        txt = lm_193(txt, rest);
      then txt;
  end matchcontinue;
end lm_193;

public function functionHeaders
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_193(out_txt, i_functions);
  out_txt := Tpl.popIter(out_txt);
end functionHeaders;

protected function lm_195
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_var_name)) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_var_name;
        SimCode.Variable i_var;
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_195(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_195(txt, rest);
      then txt;
  end matchcontinue;
end lm_195;

protected function lm_196
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_196(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_196(txt, rest);
      then txt;
  end matchcontinue;
end lm_196;

protected function lm_197
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      local
        list<String> rest;
        String i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_197(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_197(txt, rest);
      then txt;
  end matchcontinue;
end lm_197;

public function recordDeclaration
  input Tpl.Text in_txt;
  input SimCode.RecordDeclaration in_i_recDecl;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_recDecl)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.RECORD_DECL_FULL(name = i_name, variables = i_variables, defPath = i_defPath) )
      local
        Absyn.Path i_defPath;
        list<SimCode.Variable> i_variables;
        String i_name;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_195(txt, i_variables);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("};\n"));
        txt_0 = dotPath(emptyTxt, i_defPath);
        txt_1 = underscorePath(emptyTxt, i_defPath);
        txt_2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_196(txt_2, i_variables);
        txt_2 = Tpl.popIter(txt_2);
        txt = recordDefinition(txt, Tpl.textString(txt_0), Tpl.textString(txt_1), Tpl.textString(txt_2));
      then txt;

    case ( txt,
           SimCode.RECORD_DECL_DEF(path = i_path, fieldNames = i_fieldNames) )
      local
        list<String> i_fieldNames;
        Absyn.Path i_path;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt_0 = dotPath(emptyTxt, i_path);
        txt_1 = underscorePath(emptyTxt, i_path);
        txt_2 = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_197(txt_2, i_fieldNames);
        txt_2 = Tpl.popIter(txt_2);
        txt = recordDefinition(txt, Tpl.textString(txt_0), Tpl.textString(txt_1), Tpl.textString(txt_2));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end recordDeclaration;

public function recordDefinition
  input Tpl.Text txt;
  input String i_origName;
  input String i_encName;
  input String i_fieldNames;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("__desc__fields[] = {"));
  out_txt := Tpl.writeStr(out_txt, i_fieldNames);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "};\n",
                                       "struct record_description "
                                   }, false));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__desc = {\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("\""));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\", /* package_record__X */\n",
                                       "\""
                                   }, false));
  out_txt := Tpl.writeStr(out_txt, i_origName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("\", /* package.record_X */\n"));
  out_txt := Tpl.writeStr(out_txt, i_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__desc__fields\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("};"));
end recordDefinition;

public function functionHeader
  input Tpl.Text txt;
  input String i_fname;
  input list<SimCode.Variable> i_fargs;
  input list<SimCode.Variable> i_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := functionHeaderImpl(txt, i_fname, i_fargs, i_outVars, false);
end functionHeader;

protected function fun_201
  input Tpl.Text in_txt;
  input Boolean in_it;
  input String in_i_fname;
  input list<SimCode.Variable> in_i_fargs;
  input list<SimCode.Variable> in_i_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fname, in_i_fargs, in_i_outVars)
    local
      Tpl.Text txt;
      String i_fname;
      list<SimCode.Variable> i_fargs;
      list<SimCode.Variable> i_outVars;

    case ( txt,
           false,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_fname,
           i_fargs,
           i_outVars )
      equation
        txt = functionHeaderImpl(txt, i_fname, i_fargs, i_outVars, true);
      then txt;
  end matchcontinue;
end fun_201;

public function functionHeaderBoxed
  input Tpl.Text txt;
  input String i_fname;
  input list<SimCode.Variable> i_fargs;
  input list<SimCode.Variable> i_outVars;

  output Tpl.Text out_txt;
protected
  Boolean ret_0;
algorithm
  ret_0 := RTOpts.acceptMetaModelicaGrammar();
  out_txt := fun_201(txt, ret_0, i_fname, i_fargs, i_outVars);
end functionHeaderBoxed;

protected function lm_203
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_203(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_203(txt, rest);
      then txt;
  end matchcontinue;
end lm_203;

protected function lm_204
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_204(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_204(txt, rest);
      then txt;
  end matchcontinue;
end lm_204;

protected function fun_205
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;
  input list<SimCode.Variable> in_i_fargs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed, in_i_fargs)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_fargs;

    case ( txt,
           false,
           i_fargs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_203(txt, i_fargs);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           i_fargs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_204(txt, i_fargs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_205;

protected function fun_206
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed)
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
end fun_206;

protected function fun_207
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed)
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
end fun_207;

protected function fun_208
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;
  input String in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed, in_i_fname)
    local
      Tpl.Text txt;
      String i_fname;

    case ( txt,
           false,
           i_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "DLLExport\n",
                                    "int in_"
                                }, false));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(type_description * inArgs, type_description * outVar);"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_208;

protected function lm_209
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_boxStr;
  input String in_i_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_boxStr, in_i_fname)
    local
      Tpl.Text txt;
      Tpl.Text i_boxStr;
      String i_fname;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = _) :: rest,
           i_boxStr,
           i_fname )
      local
        list<SimCode.Variable> rest;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeStr(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, i_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.nextIter(txt);
        txt = lm_209(txt, rest, i_boxStr, i_fname);
      then txt;

    case ( txt,
           _ :: rest,
           i_boxStr,
           i_fname )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_209(txt, rest, i_boxStr, i_fname);
      then txt;
  end matchcontinue;
end lm_209;

protected function fun_210
  input Tpl.Text in_txt;
  input Option<Integer> in_i_dim;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_dim)
    local
      Tpl.Text txt;

    case ( txt,
           SOME(i_d) )
      local
        Integer i_d;
      equation
        txt = Tpl.writeStr(txt, intString(i_d));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"));
      then txt;
  end matchcontinue;
end fun_210;

protected function lm_211
  input Tpl.Text in_txt;
  input list<Option<Integer>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      local
        list<Option<Integer>> rest;
        Option<Integer> i_dim;
      equation
        txt = fun_210(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_211(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Option<Integer>> rest;
      equation
        txt = lm_211(txt, rest);
      then txt;
  end matchcontinue;
end lm_211;

protected function fun_212
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(arrayDimensions = i_arrayDimensions) )
      local
        list<Option<Integer>> i_arrayDimensions;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_211(txt, i_arrayDimensions);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_212;

protected function fun_213
  input Tpl.Text in_txt;
  input Boolean in_i_boxed;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_boxed, in_i_var)
    local
      Tpl.Text txt;
      SimCode.Variable i_var;

    case ( txt,
           false,
           i_var )
      equation
        txt = varType(txt, i_var);
      then txt;

    case ( txt,
           _,
           i_var )
      equation
        txt = varTypeBoxed(txt, i_var);
      then txt;
  end matchcontinue;
end fun_213;

protected function lm_214
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Boolean in_i_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_boxed)
    local
      Tpl.Text txt;
      Boolean i_boxed;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(ty = i_ty, name = i_name)) :: rest,
           i_boxed )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
        SimCode.Variable i_var;
        Integer i_i1;
        Tpl.Text i_typeStr;
        Tpl.Text i_dimStr;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        i_dimStr = fun_212(emptyTxt, i_ty);
        i_typeStr = fun_213(emptyTxt, i_boxed, i_var);
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeText(txt, i_dimStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_214(txt, rest, i_boxed);
      then txt;

    case ( txt,
           _ :: rest,
           i_boxed )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_214(txt, rest, i_boxed);
      then txt;
  end matchcontinue;
end lm_214;

public function functionHeaderImpl
  input Tpl.Text txt;
  input String i_fname;
  input list<SimCode.Variable> i_fargs;
  input list<SimCode.Variable> i_outVars;
  input Boolean i_boxed;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_inFnStr;
  Tpl.Text i_boxPtrStr;
  Tpl.Text i_boxStr;
  Tpl.Text i_fargsStr;
algorithm
  i_fargsStr := fun_205(emptyTxt, i_boxed, i_fargs);
  i_boxStr := fun_206(emptyTxt, i_boxed);
  i_boxPtrStr := fun_207(emptyTxt, i_boxed);
  i_inFnStr := fun_208(emptyTxt, i_boxed, i_fname);
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_209(out_txt, i_outVars, i_boxStr, i_fname);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("typedef struct "));
  out_txt := Tpl.writeStr(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_rettype"));
  out_txt := Tpl.writeText(out_txt, i_boxStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "_s\n",
                                       "{\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_214(out_txt, i_outVars, i_boxed);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("} "));
  out_txt := Tpl.writeStr(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_rettype"));
  out_txt := Tpl.writeText(out_txt, i_boxStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(";\n"));
  out_txt := Tpl.writeText(out_txt, i_inFnStr);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "DLLExport\n"
                                   }, true));
  out_txt := Tpl.writeStr(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_rettype"));
  out_txt := Tpl.writeText(out_txt, i_boxStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" "));
  out_txt := Tpl.writeText(out_txt, i_boxPtrStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_"));
  out_txt := Tpl.writeStr(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.writeText(out_txt, i_fargsStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(");"));
end functionHeaderImpl;

public function funArgName
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) )
      local
        DAE.ComponentRef i_name;
      equation
        txt = crefStr(txt, i_name);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgName;

public function funArgDefinition
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) )
      local
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr "));
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgDefinition;

public function funArgBoxedDefinition
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) )
      local
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_metatype "));
        txt = crefStr(txt, i_name);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name) )
      local
        String i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr "));
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgBoxedDefinition;

public function extFunDef
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_func as SimCode.EXTERNAL_FUNCTION(extName = i_extName, language = i_language, extArgs = i_extArgs, extReturn = i_extReturn)) )
      local
        SimCode.SimExtArg i_extReturn;
        list<SimCode.SimExtArg> i_extArgs;
        String i_language;
        String i_extName;
        SimCode.Function i_func;
        Tpl.Text i_fargsStr;
        Tpl.Text i_fn__name;
      equation
        i_fn__name = extFunctionName(emptyTxt, i_extName, i_language);
        i_fargsStr = extFunDefArgs(emptyTxt, i_extArgs, i_language);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("extern "));
        txt = extReturnType(txt, i_extReturn);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_fn__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_fargsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDef;

protected function fun_220
  input Tpl.Text in_txt;
  input String in_i_language;
  input String in_i_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_language, in_i_name)
    local
      Tpl.Text txt;
      String i_name;

    case ( txt,
           "C",
           i_name )
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           "FORTRAN 77",
           i_name )
      equation
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNSUPPORTED_LANGUAGE"));
      then txt;
  end matchcontinue;
end fun_220;

public function extFunctionName
  input Tpl.Text txt;
  input String i_name;
  input String i_language;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_220(txt, i_language, i_name);
end extFunctionName;

protected function lm_222
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunDefArg(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_222(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_222(txt, rest);
      then txt;
  end matchcontinue;
end lm_222;

protected function lm_223
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunDefArgF77(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_223(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_223(txt, rest);
      then txt;
  end matchcontinue;
end lm_223;

protected function fun_224
  input Tpl.Text in_txt;
  input String in_i_language;
  input list<SimCode.SimExtArg> in_i_args;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_language, in_i_args)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> i_args;

    case ( txt,
           "C",
           i_args )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_222(txt, i_args);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           "FORTRAN 77",
           i_args )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_223(txt, i_args);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNSUPPORTED_LANGUAGE"));
      then txt;
  end matchcontinue;
end fun_224;

public function extFunDefArgs
  input Tpl.Text txt;
  input list<SimCode.SimExtArg> i_args;
  input String i_language;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_224(txt, i_language, i_args);
end extFunDefArgs;

public function extReturnType
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extArg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(type_ = i_type__) )
      local
        DAE.ExpType i_type__;
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
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

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
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
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
      local
        Absyn.Path i_rname;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_rname);
      then txt;

    case ( txt,
           DAE.ET_METAOPTION(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_LIST(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_METATUPLE(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_UNIONTYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_POLYMORPHIC() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_META_ARRAY(ty = _) )
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

protected function fun_228
  input Tpl.Text in_txt;
  input String in_it;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_t)
    local
      Tpl.Text txt;
      DAE.ExpType i_t;

    case ( txt,
           "const char*",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* const *"));
      then txt;

    case ( txt,
           _,
           i_t )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const "));
        txt = extType(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" *"));
      then txt;
  end matchcontinue;
end fun_228;

protected function fun_229
  input Tpl.Text in_txt;
  input Boolean in_i_ia;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ia, in_i_t)
    local
      Tpl.Text txt;
      DAE.ExpType i_t;

    case ( txt,
           false,
           i_t )
      equation
        txt = extType(txt, i_t);
      then txt;

    case ( txt,
           _,
           i_t )
      local
        String str_1;
        Tpl.Text txt_0;
      equation
        txt_0 = extType(emptyTxt, i_t);
        str_1 = Tpl.textString(txt_0);
        txt = fun_228(txt, str_1, i_t);
      then txt;
  end matchcontinue;
end fun_229;

protected function fun_230
  input Tpl.Text in_txt;
  input Boolean in_i_ii;
  input Boolean in_i_ia;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ii, in_i_ia, in_i_t)
    local
      Tpl.Text txt;
      Boolean i_ia;
      DAE.ExpType i_t;

    case ( txt,
           false,
           _,
           i_t )
      equation
        txt = extType(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*"));
      then txt;

    case ( txt,
           _,
           i_ia,
           i_t )
      equation
        txt = fun_229(txt, i_ia, i_t);
      then txt;
  end matchcontinue;
end fun_230;

public function extFunDefArg
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extArg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = i_ii, isArray = i_ia, type_ = i_t) )
      local
        DAE.ExpType i_t;
        Boolean i_ia;
        Boolean i_ii;
        DAE.ComponentRef i_c;
        Tpl.Text i_typeStr;
        Tpl.Text i_name;
      equation
        i_name = crefStr(emptyTxt, i_c);
        i_typeStr = fun_230(emptyTxt, i_ii, i_ia, i_t);
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_name);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGEXP(type_ = i_type__) )
      local
        DAE.ExpType i_type__;
        Tpl.Text i_typeStr;
      equation
        i_typeStr = extType(emptyTxt, i_type__);
        txt = Tpl.writeText(txt, i_typeStr);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, exp = i_exp) )
      local
        DAE.Exp i_exp;
        DAE.ComponentRef i_c;
        Tpl.Text i_eStr;
        Tpl.Text i_name;
      equation
        i_name = crefStr(emptyTxt, i_c);
        i_eStr = daeExpToString(emptyTxt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size_t "));
        txt = Tpl.writeText(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeText(txt, i_eStr);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDefArg;

public function extFunDefArgF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extArg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = true, type_ = i_t) )
      local
        DAE.ExpType i_t;
        DAE.ComponentRef i_c;
        Tpl.Text i_typeStr;
        Tpl.Text i_name;
      equation
        i_name = crefStr(emptyTxt, i_c);
        i_typeStr = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("const "));
        i_typeStr = extType(i_typeStr, i_t);
        i_typeStr = Tpl.writeTok(i_typeStr, Tpl.ST_STRING(" *"));
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_name);
      then txt;

    case ( txt,
           (i_extArg as SimCode.SIMEXTARG(cref = _)) )
      local
        SimCode.SimExtArg i_extArg;
      equation
        txt = extFunDefArg(txt, i_extArg);
      then txt;

    case ( txt,
           (i_extArg as SimCode.SIMEXTARGEXP(exp = _)) )
      local
        SimCode.SimExtArg i_extArg;
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
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_varDecls;
  Tpl.Text i_preExp;
algorithm
  i_preExp := emptyTxt;
  i_varDecls := emptyTxt;
  (out_txt, i_preExp, i_varDecls) := daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
end daeExpToString;

protected function lm_234
  input Tpl.Text in_txt;
  input list<SimCode.Function> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_fn :: rest )
      local
        list<SimCode.Function> rest;
        SimCode.Function i_fn;
      equation
        txt = functionBody(txt, i_fn);
        txt = Tpl.nextIter(txt);
        txt = lm_234(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Function> rest;
      equation
        txt = lm_234(txt, rest);
      then txt;
  end matchcontinue;
end lm_234;

public function functionBodies
  input Tpl.Text txt;
  input list<SimCode.Function> i_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_234(out_txt, i_functions);
  out_txt := Tpl.popIter(out_txt);
end functionBodies;

public function functionBody
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_fn as SimCode.FUNCTION(name = _)) )
      local
        SimCode.Function i_fn;
      equation
        txt = functionBodyRegularFunction(txt, i_fn);
      then txt;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(name = _)) )
      local
        SimCode.Function i_fn;
      equation
        txt = functionBodyExternalFunction(txt, i_fn);
      then txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = _)) )
      local
        SimCode.Function i_fn;
      equation
        txt = functionBodyRecordConstructor(txt, i_fn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBody;

protected function lm_237
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varInits;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInits;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varInits, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varInits, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varInits;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varInits,
           i_varDecls )
      then (txt, i_varInits, i_varDecls);

    case ( txt,
           i_var :: rest,
           i_varInits,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        (txt, i_varDecls, i_varInits) = varInit(txt, i_var, "", i_i1, i_varDecls, i_varInits);
        txt = Tpl.nextIter(txt);
        (txt, i_varInits, i_varDecls) = lm_237(txt, rest, i_varInits, i_varDecls);
      then (txt, i_varInits, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varInits,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varInits, i_varDecls) = lm_237(txt, rest, i_varInits, i_varDecls);
      then (txt, i_varInits, i_varDecls);
  end matchcontinue;
end lm_237;

protected function lm_238
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_var :: rest,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        (txt, i_varDecls) = functionArg(txt, i_var, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_238(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varDecls) = lm_238(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_238;

protected function lm_239
  input Tpl.Text in_txt;
  input list<SimCode.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<SimCode.Statement> rest;
        SimCode.Statement i_stmt;
      equation
        (txt, i_varDecls) = funStatement(txt, i_stmt, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_239(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.Statement> rest;
      equation
        (txt, i_varDecls) = lm_239(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_239;

protected function lm_240
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_outVarInits;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_retVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_outVarInits;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_outVarInits, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_outVarInits, in_i_varDecls, in_i_retVar)
    local
      Tpl.Text txt;
      Tpl.Text i_outVarInits;
      Tpl.Text i_varDecls;
      Tpl.Text i_retVar;

    case ( txt,
           {},
           i_outVarInits,
           i_varDecls,
           _ )
      then (txt, i_outVarInits, i_varDecls);

    case ( txt,
           i_var :: rest,
           i_outVarInits,
           i_varDecls,
           i_retVar )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        (txt, i_varDecls, i_outVarInits) = varOutput(txt, i_var, Tpl.textString(i_retVar), i_i1, i_varDecls, i_outVarInits);
        txt = Tpl.nextIter(txt);
        (txt, i_outVarInits, i_varDecls) = lm_240(txt, rest, i_outVarInits, i_varDecls, i_retVar);
      then (txt, i_outVarInits, i_varDecls);

    case ( txt,
           _ :: rest,
           i_outVarInits,
           i_varDecls,
           i_retVar )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_outVarInits, i_varDecls) = lm_240(txt, rest, i_outVarInits, i_varDecls, i_retVar);
      then (txt, i_outVarInits, i_varDecls);
  end matchcontinue;
end lm_240;

protected function fun_241
  input Tpl.Text in_txt;
  input Boolean in_it;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fn)
    local
      Tpl.Text txt;
      SimCode.Function i_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_fn )
      equation
        txt = functionBodyBoxed(txt, i_fn);
      then txt;
  end matchcontinue;
end fun_241;

protected function lm_242
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_242(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_242(txt, rest);
      then txt;
  end matchcontinue;
end lm_242;

protected function lm_243
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_243(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_243(txt, rest);
      then txt;
  end matchcontinue;
end lm_243;

protected function lm_244
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        txt = readInVar(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_244(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_244(txt, rest);
      then txt;
  end matchcontinue;
end lm_244;

protected function lm_245
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgName(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_245(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_245(txt, rest);
      then txt;
  end matchcontinue;
end lm_245;

protected function lm_246
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = writeOutVar(txt, i_var, i_i1);
        txt = Tpl.nextIter(txt);
        txt = lm_246(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_246(txt, rest);
      then txt;
  end matchcontinue;
end lm_246;

protected function fun_247
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_i_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outVars)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_noretcall(outVar);"));
      then txt;

    case ( txt,
           i_outVars )
      local
        list<SimCode.Variable> i_outVars;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_246(txt, i_outVars);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_247;

public function functionBodyRegularFunction
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_fn as SimCode.FUNCTION(name = i_name, variableDeclarations = i_variableDeclarations, functionArguments = i_functionArguments, body = i_body, outVars = i_outVars)) )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Statement> i_body;
        list<SimCode.Variable> i_functionArguments;
        list<SimCode.Variable> i_variableDeclarations;
        Absyn.Path i_name;
        SimCode.Function i_fn;
        Boolean ret_12;
        Tpl.Text i_boxedFn;
        Tpl.Text i_outVarsStr;
        Tpl.Text i_outVarInits;
        Tpl.Text i_bodyPart;
        Tpl.Text i_funArgs;
        Tpl.Text i_0__;
        Tpl.Text i_stateVar;
        Tpl.Text i_retVar;
        Tpl.Text i_varInits;
        Tpl.Text i_varDecls;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
      equation
        System.tmpTickReset(1);
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = Tpl.writeText(emptyTxt, i_fname);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        i_varDecls = emptyTxt;
        i_varInits = emptyTxt;
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        i_0__ = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, NONE, 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_0__, i_varInits, i_varDecls) = lm_237(i_0__, i_variableDeclarations, i_varInits, i_varDecls);
        i_0__ = Tpl.popIter(i_0__);
        i_funArgs = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_funArgs, i_varDecls) = lm_238(i_funArgs, i_functionArguments, i_varDecls);
        i_funArgs = Tpl.popIter(i_funArgs);
        i_bodyPart = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_bodyPart, i_varDecls) = lm_239(i_bodyPart, i_body, i_varDecls);
        i_bodyPart = Tpl.popIter(i_bodyPart);
        i_outVarInits = emptyTxt;
        i_outVarsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_outVarsStr, i_outVarInits, i_varDecls) = lm_240(i_outVarsStr, i_outVars, i_outVarInits, i_varDecls, i_retVar);
        i_outVarsStr = Tpl.popIter(i_outVarsStr);
        ret_12 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedFn = fun_241(emptyTxt, ret_12, i_fn);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_242(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_funArgs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_outVarInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = get_memory_state();\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_varInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_bodyPart);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "_return:\n"
                                }, true));
        txt = Tpl.writeText(txt, i_outVarsStr);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "return "
                                }, false));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n",
                                    "int in_"
                                }, false));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(type_description * inArgs, type_description * outVar)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_243(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" out;\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_244(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out = _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_245(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = fun_247(txt, i_outVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_boxedFn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyRegularFunction;

protected function lm_249
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_outputAlloc;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_outputAlloc;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_outputAlloc, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_outputAlloc, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_outputAlloc;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_outputAlloc,
           i_varDecls )
      then (txt, i_outputAlloc, i_varDecls);

    case ( txt,
           i_var :: rest,
           i_outputAlloc,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        (txt, i_varDecls, i_outputAlloc) = varInit(txt, i_var, "out", i_i1, i_varDecls, i_outputAlloc);
        txt = Tpl.nextIter(txt);
        (txt, i_outputAlloc, i_varDecls) = lm_249(txt, rest, i_outputAlloc, i_varDecls);
      then (txt, i_outputAlloc, i_varDecls);

    case ( txt,
           _ :: rest,
           i_outputAlloc,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_outputAlloc, i_varDecls) = lm_249(txt, rest, i_outputAlloc, i_varDecls);
      then (txt, i_outputAlloc, i_varDecls);
  end matchcontinue;
end lm_249;

protected function fun_250
  input Tpl.Text in_txt;
  input Boolean in_it;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fn)
    local
      Tpl.Text txt;
      SimCode.Function i_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_fn )
      equation
        txt = functionBodyBoxed(txt, i_fn);
      then txt;
  end matchcontinue;
end fun_250;

protected function lm_251
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_251(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_251(txt, rest);
      then txt;
  end matchcontinue;
end lm_251;

protected function lm_252
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_arg as SimCode.VARIABLE(name = _)) :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        txt = readInVar(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_252(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_252(txt, rest);
      then txt;
  end matchcontinue;
end lm_252;

protected function lm_253
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
      equation
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_253(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_253(txt, rest);
      then txt;
  end matchcontinue;
end lm_253;

protected function lm_254
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = _)) :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = writeOutVar(txt, i_var, i_i1);
        txt = Tpl.nextIter(txt);
        txt = lm_254(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_254(txt, rest);
      then txt;
  end matchcontinue;
end lm_254;

protected function lm_255
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_255(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_255(txt, rest);
      then txt;
  end matchcontinue;
end lm_255;

public function functionBodyExternalFunction
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(name = i_name, outVars = i_outVars, funArgs = i_funArgs)) )
      local
        list<SimCode.Variable> i_funArgs;
        list<SimCode.Variable> i_outVars;
        Absyn.Path i_name;
        SimCode.Function i_fn;
        Boolean ret_9;
        Tpl.Text i_boxedFn;
        Tpl.Text i_0__;
        Tpl.Text i_callPart;
        Tpl.Text i_stateVar;
        Tpl.Text i_outputAlloc;
        Tpl.Text i_varDecls;
        Tpl.Text i_preExp;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
      equation
        System.tmpTickReset(1);
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = Tpl.writeText(emptyTxt, i_fname);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        i_preExp = emptyTxt;
        i_varDecls = emptyTxt;
        i_outputAlloc = emptyTxt;
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        (i_callPart, i_preExp, i_varDecls) = extFunCall(emptyTxt, i_fn, i_preExp, i_varDecls);
        i_0__ = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, NONE, 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_0__, i_outputAlloc, i_varDecls) = lm_249(i_0__, i_outVars, i_outputAlloc, i_varDecls);
        i_0__ = Tpl.popIter(i_0__);
        ret_9 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedFn = fun_250(emptyTxt, ret_9, i_fn);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int in_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(type_description * inArgs, type_description * outVar)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_251(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" out;\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_252(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out = _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_253(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_254(txt, i_outVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_255(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" out;\n"));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" = get_memory_state();\n"));
        txt = Tpl.writeText(txt, i_outputAlloc);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_callPart);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "return out;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_boxedFn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyExternalFunction;

protected function fun_257
  input Tpl.Text in_txt;
  input Boolean in_it;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_fn)
    local
      Tpl.Text txt;
      SimCode.Function i_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           i_fn )
      equation
        txt = functionBodyBoxed(txt, i_fn);
      then txt;
  end matchcontinue;
end fun_257;

protected function lm_258
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_258(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_258(txt, rest);
      then txt;
  end matchcontinue;
end lm_258;

protected function lm_259
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_structVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_structVar)
    local
      Tpl.Text txt;
      Tpl.Text i_structVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest,
           i_structVar )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeText(txt, i_structVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_259(txt, rest, i_structVar);
      then txt;

    case ( txt,
           _ :: rest,
           i_structVar )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_259(txt, rest, i_structVar);
      then txt;
  end matchcontinue;
end lm_259;

public function functionBodyRecordConstructor
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs)) )
      local
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        SimCode.Function i_fn;
        Boolean ret_7;
        Tpl.Text i_boxedFn;
        Tpl.Text i_structVar;
        Tpl.Text i_structType;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
        Tpl.Text i_varDecls;
      equation
        System.tmpTickReset(1);
        i_varDecls = emptyTxt;
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = Tpl.writeText(emptyTxt, i_fname);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_structType = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("struct "));
        i_structType = Tpl.writeText(i_structType, i_fname);
        (i_structVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_structType), i_varDecls);
        ret_7 = RTOpts.acceptMetaModelicaGrammar();
        i_boxedFn = fun_257(emptyTxt, ret_7, i_fn);
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_258(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_259(txt, i_funArgs, i_structVar);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ1 = "));
        txt = Tpl.writeText(txt, i_structVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "return "
                                }, false));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_boxedFn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyRecordConstructor;

public function functionBodyBoxed
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.FUNCTION(name = i_name, functionArguments = i_functionArguments, outVars = i_outVars) )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_functionArguments;
        Absyn.Path i_name;
      equation
        txt = functionBodyBoxedImpl(txt, i_name, i_functionArguments, i_outVars);
      then txt;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(name = i_name, funArgs = i_funArgs, outVars = i_outVars) )
      local
        list<SimCode.Variable> i_outVars;
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
      equation
        txt = functionBodyBoxedImpl(txt, i_name, i_funArgs, i_outVars);
      then txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = _)) )
      local
        SimCode.Function i_fn;
      equation
        txt = boxRecordConstructor(txt, i_fn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyBoxed;

protected function lm_262
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varBox;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varBox;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varBox, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varBox, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varBox;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varBox,
           i_varDecls )
      then (txt, i_varBox, i_varDecls);

    case ( txt,
           i_arg :: rest,
           i_varBox,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        (txt, i_varDecls, i_varBox) = funArgUnbox(txt, i_arg, i_varDecls, i_varBox);
        txt = Tpl.nextIter(txt);
        (txt, i_varBox, i_varDecls) = lm_262(txt, rest, i_varBox, i_varDecls);
      then (txt, i_varBox, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varBox,
           i_varDecls )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varBox, i_varDecls) = lm_262(txt, rest, i_varBox, i_varDecls);
      then (txt, i_varBox, i_varDecls);
  end matchcontinue;
end lm_262;

protected function lm_263
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varUnbox;
  input Tpl.Text in_i_retTypeBoxed;
  input Tpl.Text in_i_retVar;
  input Tpl.Text in_i_retType;
  input Tpl.Text in_i_funRetVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varUnbox;
algorithm
  (out_txt, out_i_varDecls, out_i_varUnbox) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_varUnbox, in_i_retTypeBoxed, in_i_retVar, in_i_retType, in_i_funRetVar)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varUnbox;
      Tpl.Text i_retTypeBoxed;
      Tpl.Text i_retVar;
      Tpl.Text i_retType;
      Tpl.Text i_funRetVar;

    case ( txt,
           {},
           i_varDecls,
           i_varUnbox,
           _,
           _,
           _,
           _ )
      then (txt, i_varDecls, i_varUnbox);

    case ( txt,
           (i_var as SimCode.VARIABLE(ty = i_ty)) :: rest,
           i_varDecls,
           i_varUnbox,
           i_retTypeBoxed,
           i_retVar,
           i_retType,
           i_funRetVar )
      local
        list<SimCode.Variable> rest;
        DAE.ExpType i_ty;
        SimCode.Variable i_var;
        Integer i_i1;
        Tpl.Text i_arg;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        i_arg = Tpl.writeText(emptyTxt, i_funRetVar);
        i_arg = Tpl.writeTok(i_arg, Tpl.ST_STRING("."));
        i_arg = Tpl.writeText(i_arg, i_retType);
        i_arg = Tpl.writeTok(i_arg, Tpl.ST_STRING("_"));
        i_arg = Tpl.writeStr(i_arg, intString(i_i1));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_retTypeBoxed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, i_varUnbox, i_varDecls) = funArgBox(txt, Tpl.textString(i_arg), i_ty, i_varUnbox, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_varUnbox) = lm_263(txt, rest, i_varDecls, i_varUnbox, i_retTypeBoxed, i_retVar, i_retType, i_funRetVar);
      then (txt, i_varDecls, i_varUnbox);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_varUnbox,
           i_retTypeBoxed,
           i_retVar,
           i_retType,
           i_funRetVar )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varDecls, i_varUnbox) = lm_263(txt, rest, i_varDecls, i_varUnbox, i_retTypeBoxed, i_retVar, i_retType, i_funRetVar);
      then (txt, i_varDecls, i_varUnbox);
  end matchcontinue;
end lm_263;

protected function lm_264
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_264(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_264(txt, rest);
      then txt;
  end matchcontinue;
end lm_264;

public function functionBodyBoxedImpl
  input Tpl.Text txt;
  input Absyn.Path i_name;
  input list<SimCode.Variable> i_funargs;
  input list<SimCode.Variable> i_outvars;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_retStr;
  Tpl.Text i_args;
  Tpl.Text i_varUnbox;
  Tpl.Text i_varBox;
  Tpl.Text i_stateVar;
  Tpl.Text i_funRetVar;
  Tpl.Text i_retVar;
  Tpl.Text i_varDecls;
  Tpl.Text i_retTypeBoxed;
  Tpl.Text i_retType;
  Tpl.Text i_fname;
algorithm
  System.tmpTickReset(1);
  i_fname := underscorePath(emptyTxt, i_name);
  i_retType := Tpl.writeText(emptyTxt, i_fname);
  i_retType := Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
  i_retTypeBoxed := Tpl.writeText(emptyTxt, i_retType);
  i_retTypeBoxed := Tpl.writeTok(i_retTypeBoxed, Tpl.ST_STRING("boxed"));
  i_varDecls := emptyTxt;
  (i_retVar, i_varDecls) := tempDecl(emptyTxt, Tpl.textString(i_retTypeBoxed), i_varDecls);
  (i_funRetVar, i_varDecls) := tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
  (i_stateVar, i_varDecls) := tempDecl(emptyTxt, "state", i_varDecls);
  i_varBox := emptyTxt;
  i_varUnbox := emptyTxt;
  i_args := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_args, i_varBox, i_varDecls) := lm_262(i_args, i_funargs, i_varBox, i_varDecls);
  i_args := Tpl.popIter(i_args);
  i_retStr := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_retStr, i_varDecls, i_varUnbox) := lm_263(i_retStr, i_outvars, i_varDecls, i_varUnbox, i_retTypeBoxed, i_retVar, i_retType, i_funRetVar);
  i_retStr := Tpl.popIter(i_retStr);
  out_txt := Tpl.writeText(txt, i_retTypeBoxed);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" boxptr_"));
  out_txt := Tpl.writeText(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_264(out_txt, i_funargs);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ")\n",
                                       "{\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(" = get_memory_state();\n"));
  out_txt := Tpl.writeText(out_txt, i_varBox);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_funRetVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" = _"));
  out_txt := Tpl.writeText(out_txt, i_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.writeText(out_txt, i_args);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(");\n"));
  out_txt := Tpl.writeText(out_txt, i_varUnbox);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_retStr);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("restore_memory_state("));
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ");\n",
                                       "return "
                                   }, false));
  out_txt := Tpl.writeText(out_txt, i_retVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(";\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionBodyBoxedImpl;

protected function lm_266
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) :: rest )
      local
        list<SimCode.Variable> rest;
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
      equation
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_266(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_266(txt, rest);
      then txt;
  end matchcontinue;
end lm_266;

protected function lm_267
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_267(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_267(txt, rest);
      then txt;
  end matchcontinue;
end lm_267;

public function boxRecordConstructor
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_fn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs) )
      local
        list<SimCode.Variable> i_funArgs;
        Absyn.Path i_name;
        Integer ret_10;
        Integer ret_9;
        Tpl.Text i_funArgCount;
        Tpl.Text i_boxRetVar;
        Tpl.Text i_funArgsStr;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_fname;
        Tpl.Text i_stateVar;
        Tpl.Text i_preExp;
        Tpl.Text i_varDecls;
      equation
        System.tmpTickReset(1);
        i_varDecls = emptyTxt;
        i_preExp = emptyTxt;
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        i_fname = underscorePath(emptyTxt, i_name);
        i_retType = Tpl.writeText(emptyTxt, i_fname);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettypeboxed"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_funArgsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_funArgsStr = lm_266(i_funArgsStr, i_funArgs);
        i_funArgsStr = Tpl.popIter(i_funArgsStr);
        (i_boxRetVar, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        ret_9 = listLength(i_funArgs);
        ret_10 = SimCode.incrementInt(ret_9, 1);
        i_funArgCount = Tpl.writeStr(emptyTxt, intString(ret_10));
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" boxptr_"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_267(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = get_memory_state();\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_boxRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = mmc_mk_box"));
        txt = Tpl.writeText(txt, i_funArgCount);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(3, &"));
        txt = Tpl.writeText(txt, i_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc, "));
        txt = Tpl.writeText(txt, i_funArgsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1 = "));
        txt = Tpl.writeText(txt, i_boxRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "\n",
                                    "restore_memory_state("
                                }, false));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "return "
                                }, false));
        txt = Tpl.writeText(txt, i_retVar);
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
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varBox;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varBox;
algorithm
  (out_txt, out_i_varDecls, out_i_varBox) :=
  matchcontinue(in_txt, in_i_var, in_i_varDecls, in_i_varBox)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varBox;

    case ( txt,
           SimCode.VARIABLE(name = i_name, ty = i_ty),
           i_varDecls,
           i_varBox )
      local
        DAE.ExpType i_ty;
        DAE.ComponentRef i_name;
        Tpl.Text i_varName;
      equation
        i_varName = crefStr(emptyTxt, i_name);
        (txt, i_varBox, i_varDecls) = unboxVariable(txt, Tpl.textString(i_varName), i_ty, i_varBox, i_varDecls);
      then (txt, i_varDecls, i_varBox);

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name),
           i_varDecls,
           i_varBox )
      local
        String i_name;
      equation
        txt = Tpl.writeStr(txt, i_name);
      then (txt, i_varDecls, i_varBox);

    case ( txt,
           _,
           i_varDecls,
           i_varBox )
      then (txt, i_varDecls, i_varBox);
  end matchcontinue;
end funArgUnbox;

protected function fun_270
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_shortType;
  input String in_i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_preExp, in_i_varDecls, in_i_shortType, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;
      Tpl.Text i_shortType;
      String i_varName;

    case ( txt,
           "",
           i_preExp,
           i_varDecls,
           _,
           i_varName )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls,
           i_shortType,
           i_varName )
      local
        Tpl.Text txt_2;
        Tpl.Text i_tmpVar;
        Tpl.Text i_type;
      equation
        i_type = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("mmc__unbox__"));
        i_type = Tpl.writeText(i_type, i_shortType);
        i_type = Tpl.writeTok(i_type, Tpl.ST_STRING("_rettype"));
        txt_2 = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("mmc__unbox__"));
        txt_2 = Tpl.writeText(txt_2, i_shortType);
        txt_2 = Tpl.writeTok(txt_2, Tpl.ST_STRING("_rettype"));
        (i_tmpVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_2), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmpVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = mmc__unbox__"));
        i_preExp = Tpl.writeText(i_preExp, i_shortType);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeStr(i_preExp, i_varName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpVar);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_270;

protected function fun_271
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_varType;
  input String in_i_varName;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_varType, in_i_varName, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      String i_varName;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_varType as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _))),
           i_varName,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_varType;
      equation
        (txt, i_preExp, i_varDecls) = unboxRecord(txt, i_varName, i_varType, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_varType,
           i_varName,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_varType;
        String str_1;
        Tpl.Text i_shortType;
      equation
        i_shortType = mmcExpTypeShort(emptyTxt, i_varType);
        str_1 = Tpl.textString(i_shortType);
        (txt, i_preExp, i_varDecls) = fun_270(txt, str_1, i_preExp, i_varDecls, i_shortType, i_varName);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_271;

public function unboxVariable
  input Tpl.Text txt;
  input String i_varName;
  input DAE.ExpType i_varType;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) := fun_271(txt, i_varType, i_varName, i_preExp, i_varDecls);
end unboxVariable;

protected function lm_273
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_tmpVar;
  input String in_i_recordVar;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_tmpVar, in_i_recordVar, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_tmpVar;
      String i_recordVar;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAE.COMPLEX_VAR(name = i_compname, tp = i_tp) :: rest,
           i_tmpVar,
           i_recordVar,
           i_varDecls )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpType i_tp;
        String i_compname;
        Integer i_i1;
        Tpl.Text i_unboxStr;
        Tpl.Text i_unboxBuf;
        Integer ret_3;
        Tpl.Text i_offsetStr;
        Tpl.Text i_untagTmp;
        Tpl.Text i_varType;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        i_varType = mmcExpTypeShort(emptyTxt, i_tp);
        (i_untagTmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        ret_3 = SimCode.incrementInt(i_i1, 1);
        i_offsetStr = Tpl.writeStr(emptyTxt, intString(ret_3));
        i_unboxBuf = emptyTxt;
        (i_unboxStr, i_unboxBuf, i_varDecls) = unboxVariable(emptyTxt, Tpl.textString(i_untagTmp), i_tp, i_unboxBuf, i_varDecls);
        txt = Tpl.writeText(txt, i_untagTmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        txt = Tpl.writeStr(txt, i_recordVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), "));
        txt = Tpl.writeText(txt, i_offsetStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(")));\n"));
        txt = Tpl.writeText(txt, i_unboxBuf);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_tmpVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_compname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_unboxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_273(txt, rest, i_tmpVar, i_recordVar, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_tmpVar,
           i_recordVar,
           i_varDecls )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varDecls) = lm_273(txt, rest, i_tmpVar, i_recordVar, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_273;

protected function fun_274
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input String in_i_recordVar;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ty, in_i_recordVar, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      String i_recordVar;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_path), varLst = i_vars),
           i_recordVar,
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_vars;
        Absyn.Path i_path;
        Tpl.Text txt_1;
        Tpl.Text i_tmpVar;
      equation
        txt_1 = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("struct "));
        txt_1 = underscorePath(txt_1, i_path);
        (i_tmpVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_1), i_varDecls);
        i_preExp = Tpl.pushIter(i_preExp, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_preExp, i_varDecls) = lm_273(i_preExp, i_vars, i_tmpVar, i_recordVar, i_varDecls);
        i_preExp = Tpl.popIter(i_preExp);
        txt = Tpl.writeText(txt, i_tmpVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_274;

public function unboxRecord
  input Tpl.Text txt;
  input String i_recordVar;
  input DAE.ExpType i_ty;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) := fun_274(txt, i_ty, i_recordVar, i_preExp, i_varDecls);
end unboxRecord;

protected function fun_276
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_constructorType;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varUnbox;
  input DAE.ExpType in_i_ty;
  input String in_i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varUnbox;
algorithm
  (out_txt, out_i_varDecls, out_i_varUnbox) :=
  matchcontinue(in_txt, in_it, in_i_constructorType, in_i_varDecls, in_i_varUnbox, in_i_ty, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_constructorType;
      Tpl.Text i_varDecls;
      Tpl.Text i_varUnbox;
      DAE.ExpType i_ty;
      String i_varName;

    case ( txt,
           "",
           _,
           i_varDecls,
           i_varUnbox,
           _,
           i_varName )
      equation
        txt = Tpl.writeStr(txt, i_varName);
      then (txt, i_varDecls, i_varUnbox);

    case ( txt,
           _,
           i_constructorType,
           i_varDecls,
           i_varUnbox,
           i_ty,
           i_varName )
      local
        Tpl.Text i_tmpVar;
        Tpl.Text i_constructor;
      equation
        (i_constructor, i_varUnbox, i_varDecls) = mmcConstructor(emptyTxt, i_ty, i_varName, i_varUnbox, i_varDecls);
        (i_tmpVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_constructorType), i_varDecls);
        i_varUnbox = Tpl.writeText(i_varUnbox, i_tmpVar);
        i_varUnbox = Tpl.writeTok(i_varUnbox, Tpl.ST_STRING(" = "));
        i_varUnbox = Tpl.writeText(i_varUnbox, i_constructor);
        i_varUnbox = Tpl.writeTok(i_varUnbox, Tpl.ST_STRING(";"));
        i_varUnbox = Tpl.writeTok(i_varUnbox, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpVar);
      then (txt, i_varDecls, i_varUnbox);
  end matchcontinue;
end fun_276;

public function funArgBox
  input Tpl.Text txt;
  input String i_varName;
  input DAE.ExpType i_ty;
  input Tpl.Text i_varUnbox;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varUnbox;
  output Tpl.Text out_i_varDecls;
protected
  String str_1;
  Tpl.Text i_constructorType;
algorithm
  i_constructorType := mmcConstructorType(emptyTxt, i_ty);
  str_1 := Tpl.textString(i_constructorType);
  (out_txt, out_i_varDecls, out_i_varUnbox) := fun_276(txt, str_1, i_constructorType, i_varDecls, i_varUnbox, i_ty, i_varName);
end funArgBox;

public function mmcConstructorType
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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

protected function lm_279
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input String in_i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      String i_varName;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           (i_var as DAE.COMPLEX_VAR(name = i_name, tp = i_tp)) :: rest,
           i_varDecls,
           i_preExp,
           i_varName )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpType i_tp;
        String i_name;
        DAE.ExpVar i_var;
        Tpl.Text i_varname;
      equation
        i_varname = Tpl.writeStr(emptyTxt, i_varName);
        i_varname = Tpl.writeTok(i_varname, Tpl.ST_STRING("."));
        i_varname = Tpl.writeStr(i_varname, i_name);
        (txt, i_preExp, i_varDecls) = funArgBox(txt, Tpl.textString(i_varname), i_tp, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_279(txt, rest, i_varDecls, i_preExp, i_varName);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_varName )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_279(txt, rest, i_varDecls, i_preExp, i_varName);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_279;

public function mmcConstructor
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input String in_i_varName;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_type, in_i_varName, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      String i_varName;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_INT(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_BOOL(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_STRING(),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_ARRAY(ty = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_acon("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_path), varLst = i_vars),
           i_varName,
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_vars;
        Absyn.Path i_path;
        Tpl.Text i_varsStr;
        Integer ret_2;
        Integer ret_1;
        Tpl.Text i_varCount;
      equation
        ret_1 = listLength(i_vars);
        ret_2 = SimCode.incrementInt(ret_1, 1);
        i_varCount = Tpl.writeStr(emptyTxt, intString(ret_2));
        i_varsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_varsStr, i_varDecls, i_preExp) = lm_279(i_varsStr, i_vars, i_varDecls, i_preExp, i_varName);
        i_varsStr = Tpl.popIter(i_varsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box"));
        txt = Tpl.writeText(txt, i_varCount);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(3, &"));
        txt = underscorePath(txt, i_path);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc, "));
        txt = Tpl.writeText(txt, i_varsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(name = _),
           i_varName,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box("));
        txt = Tpl.writeStr(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end mmcConstructor;

public function readInVar
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = i_cr, ty = (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)))) )
      local
        DAE.ExpType i_ty;
        DAE.ComponentRef i_cr;
        Tpl.Text txt_0;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (read_modelica_record(&inArgs, "));
        txt_0 = crefStr(emptyTxt, i_cr);
        txt = readInVarRecordMembers(txt, i_ty, Tpl.textString(txt_0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) return 1;"));
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) )
      local
        DAE.ComponentRef i_name;
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (read_"));
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&inArgs, &"));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) return 1;"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end readInVar;

protected function fun_282
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_tp;
  input String in_i_subvar_name;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_tp, in_i_subvar_name, in_i_prefix)
    local
      Tpl.Text txt;
      String i_subvar_name;
      String i_prefix;

    case ( txt,
           (i_tp as DAE.ET_COMPLEX(name = _)),
           i_subvar_name,
           i_prefix )
      local
        DAE.ExpType i_tp;
        Tpl.Text i_newPrefix;
      equation
        i_newPrefix = Tpl.writeStr(emptyTxt, i_prefix);
        i_newPrefix = Tpl.writeTok(i_newPrefix, Tpl.ST_STRING("."));
        i_newPrefix = Tpl.writeStr(i_newPrefix, i_subvar_name);
        txt = readInVarRecordMembers(txt, i_tp, Tpl.textString(i_newPrefix));
      then txt;

    case ( txt,
           _,
           i_subvar_name,
           i_prefix )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&("));
        txt = Tpl.writeStr(txt, i_prefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_subvar_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_282;

protected function lm_283
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_prefix)
    local
      Tpl.Text txt;
      String i_prefix;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           (i_subvar as DAE.COMPLEX_VAR(tp = i_tp, name = i_subvar_name)) :: rest,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
        String i_subvar_name;
        DAE.ExpType i_tp;
        DAE.ExpVar i_subvar;
      equation
        txt = fun_282(txt, i_tp, i_subvar_name, i_prefix);
        txt = Tpl.nextIter(txt);
        txt = lm_283(txt, rest, i_prefix);
      then txt;

    case ( txt,
           _ :: rest,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
      equation
        txt = lm_283(txt, rest, i_prefix);
      then txt;
  end matchcontinue;
end lm_283;

public function readInVarRecordMembers
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type, in_i_prefix)
    local
      Tpl.Text txt;
      String i_prefix;

    case ( txt,
           DAE.ET_COMPLEX(varLst = i_vl),
           i_prefix )
      local
        list<DAE.ExpVar> i_vl;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_283(txt, i_vl, i_prefix);
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
  input SimCode.Variable in_i_var;
  input Integer in_i_index;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var, in_i_index)
    local
      Tpl.Text txt;
      Integer i_index;

    case ( txt,
           SimCode.VARIABLE(ty = (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)))),
           i_index )
      local
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_modelica_record(outVar, "));
        txt = writeOutVarRecordMembers(txt, i_ty, i_index, "");
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = _)),
           i_index )
      local
        SimCode.Variable i_var;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_"));
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(outVar, &out.targ"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end writeOutVar;

protected function fun_286
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_tp;
  input Integer in_i_index;
  input String in_i_subvar_name;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_tp, in_i_index, in_i_subvar_name, in_i_prefix)
    local
      Tpl.Text txt;
      Integer i_index;
      String i_subvar_name;
      String i_prefix;

    case ( txt,
           (i_tp as DAE.ET_COMPLEX(name = _)),
           i_index,
           i_subvar_name,
           i_prefix )
      local
        DAE.ExpType i_tp;
        Tpl.Text i_newPrefix;
      equation
        i_newPrefix = Tpl.writeStr(emptyTxt, i_prefix);
        i_newPrefix = Tpl.writeTok(i_newPrefix, Tpl.ST_STRING("."));
        i_newPrefix = Tpl.writeStr(i_newPrefix, i_subvar_name);
        txt = expTypeRW(txt, i_tp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = writeOutVarRecordMembers(txt, i_tp, i_index, Tpl.textString(i_newPrefix));
      then txt;

    case ( txt,
           i_tp,
           i_index,
           i_subvar_name,
           i_prefix )
      local
        DAE.ExpType i_tp;
      equation
        txt = expTypeRW(txt, i_tp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &(out.targ"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeStr(txt, i_prefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_subvar_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_286;

protected function lm_287
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Integer in_i_index;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_i_index, in_i_prefix)
    local
      Tpl.Text txt;
      Integer i_index;
      String i_prefix;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           (i_subvar as DAE.COMPLEX_VAR(tp = i_tp, name = i_subvar_name)) :: rest,
           i_index,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
        String i_subvar_name;
        DAE.ExpType i_tp;
        DAE.ExpVar i_subvar;
      equation
        txt = fun_286(txt, i_tp, i_index, i_subvar_name, i_prefix);
        txt = Tpl.nextIter(txt);
        txt = lm_287(txt, rest, i_index, i_prefix);
      then txt;

    case ( txt,
           _ :: rest,
           i_index,
           i_prefix )
      local
        list<DAE.ExpVar> rest;
      equation
        txt = lm_287(txt, rest, i_index, i_prefix);
      then txt;
  end matchcontinue;
end lm_287;

protected function fun_288
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_args;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_args)
    local
      Tpl.Text txt;
      Tpl.Text i_args;

    case ( txt,
           "",
           _ )
      then txt;

    case ( txt,
           _,
           i_args )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_args);
      then txt;
  end matchcontinue;
end fun_288;

public function writeOutVarRecordMembers
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input Integer in_i_index;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type, in_i_index, in_i_prefix)
    local
      Tpl.Text txt;
      Integer i_index;
      String i_prefix;

    case ( txt,
           DAE.ET_COMPLEX(varLst = i_vl, name = i_n),
           i_index,
           i_prefix )
      local
        Absyn.Path i_n;
        list<DAE.ExpVar> i_vl;
        String str_2;
        Tpl.Text i_args;
        Tpl.Text i_basename;
      equation
        i_basename = underscorePath(emptyTxt, i_n);
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_args = lm_287(i_args, i_vl, i_index, i_prefix);
        i_args = Tpl.popIter(i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = Tpl.writeText(txt, i_basename);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc"));
        str_2 = Tpl.textString(i_args);
        txt = fun_288(txt, str_2, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", TYPE_DESC_NONE"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end writeOutVarRecordMembers;

protected function fun_290
  input Tpl.Text in_txt;
  input String in_i_outStruct;
  input DAE.ComponentRef in_i_var_name;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outStruct, in_i_var_name, in_i_var)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_var_name;
      SimCode.Variable i_var;

    case ( txt,
           "",
           i_var_name,
           i_var )
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_290;

protected function fun_291
  input Tpl.Text in_txt;
  input String in_i_outStruct;
  input Integer in_i_i;
  input DAE.ComponentRef in_i_var_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outStruct, in_i_i, in_i_var_name)
    local
      Tpl.Text txt;
      Integer i_i;
      DAE.ComponentRef i_var_name;

    case ( txt,
           "",
           _,
           i_var_name )
      equation
        txt = crefStr(txt, i_var_name);
      then txt;

    case ( txt,
           i_outStruct,
           i_i,
           _ )
      local
        String i_outStruct;
      equation
        txt = Tpl.writeStr(txt, i_outStruct);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
      then txt;
  end matchcontinue;
end fun_291;

protected function lm_292
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_varInits, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_varInits, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_varInits) = lm_292(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_varInits) = lm_292(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end lm_292;

protected function fun_293
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input Integer in_i_i;
  input String in_i_outStruct;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_instDimsInit;
  input Tpl.Text in_i_varName;
  input DAE.ExpType in_i_var_ty;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varInits) :=
  matchcontinue(in_txt, in_i_instDims, in_i_i, in_i_outStruct, in_i_var, in_i_instDimsInit, in_i_varName, in_i_var_ty, in_i_varInits)
    local
      Tpl.Text txt;
      Integer i_i;
      String i_outStruct;
      SimCode.Variable i_var;
      Tpl.Text i_instDimsInit;
      Tpl.Text i_varName;
      DAE.ExpType i_var_ty;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           _,
           _,
           _,
           _,
           _,
           _,
           i_varInits )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
      then (txt, i_varInits);

    case ( txt,
           i_instDims,
           i_i,
           i_outStruct,
           i_var,
           i_instDimsInit,
           i_varName,
           i_var_ty,
           i_varInits )
      local
        list<DAE.Exp> i_instDims;
        Integer ret_0;
      equation
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("alloc_"));
        i_varInits = expTypeShort(i_varInits, i_var_ty);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("_array(&"));
        i_varInits = Tpl.writeText(i_varInits, i_varName);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        ret_0 = listLength(i_instDims);
        i_varInits = Tpl.writeStr(i_varInits, intString(ret_0));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        i_varInits = Tpl.writeText(i_varInits, i_instDimsInit);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(");"));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_NEW_LINE());
        i_varInits = varDefaultValue(i_varInits, i_var, i_outStruct, i_i);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
      then (txt, i_varInits);
  end matchcontinue;
end fun_293;

public function varInit
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input String in_i_outStruct;
  input Integer in_i_i;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_var, in_i_outStruct, in_i_i, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      String i_outStruct;
      Integer i_i;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_var_name, instDims = i_instDims, ty = i_var_ty)),
           i_outStruct,
           i_i,
           i_varDecls,
           i_varInits )
      local
        DAE.ExpType i_var_ty;
        list<DAE.Exp> i_instDims;
        DAE.ComponentRef i_var_name;
        SimCode.Variable i_var;
        Tpl.Text i_instDimsInit;
        Tpl.Text i_varName;
      equation
        i_varDecls = fun_290(i_varDecls, i_outStruct, i_var_name, i_var);
        i_varName = fun_291(emptyTxt, i_outStruct, i_i, i_var_name);
        i_instDimsInit = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_instDimsInit, i_varDecls, i_varInits) = lm_292(i_instDimsInit, i_instDims, i_varDecls, i_varInits);
        i_instDimsInit = Tpl.popIter(i_instDimsInit);
        (txt, i_varInits) = fun_293(txt, i_instDims, i_i, i_outStruct, i_var, i_instDimsInit, i_varName, i_var_ty, i_varInits);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _,
           _,
           _,
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end varInit;

protected function fun_295
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_value;
  input Integer in_i_i;
  input String in_i_outStruct;
  input DAE.ExpType in_i_var_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_value, in_i_i, in_i_outStruct, in_i_var_ty)
    local
      Tpl.Text txt;
      Integer i_i;
      String i_outStruct;
      DAE.ExpType i_var_ty;

    case ( txt,
           SOME(DAE.CREF(componentRef = i_cr)),
           i_i,
           i_outStruct,
           i_var_ty )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, i_var_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data(&"));
        txt = crefStr(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, i_outStruct);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_295;

public function varDefaultValue
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input String in_i_outStruct;
  input Integer in_i_i;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var, in_i_outStruct, in_i_i)
    local
      Tpl.Text txt;
      String i_outStruct;
      Integer i_i;

    case ( txt,
           (i_var as SimCode.VARIABLE(value = i_value, ty = i_var_ty)),
           i_outStruct,
           i_i )
      local
        DAE.ExpType i_var_ty;
        Option<DAE.Exp> i_value;
        SimCode.Variable i_var;
      equation
        txt = fun_295(txt, i_value, i_i, i_outStruct, i_var_ty);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end varDefaultValue;

protected function lm_297
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        txt = mmcVarType(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_297(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_297(txt, rest);
      then txt;
  end matchcontinue;
end lm_297;

protected function lm_298
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
        Integer i_i1;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        txt = mmcVarType(txt, i_arg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_298(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.Variable> rest;
      equation
        txt = lm_298(txt, rest);
      then txt;
  end matchcontinue;
end lm_298;

protected function fun_299
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           (i_var as SimCode.FUNCTION_PTR(args = i_args, name = i_name)) )
      local
        String i_name;
        list<SimCode.Variable> i_args;
        SimCode.Variable i_var;
        Tpl.Text i_rettype;
        Tpl.Text i_typelist;
      equation
        i_typelist = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_typelist = lm_297(i_typelist, i_args);
        i_typelist = Tpl.popIter(i_typelist);
        i_rettype = Tpl.writeStr(emptyTxt, i_name);
        i_rettype = Tpl.writeTok(i_rettype, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_s\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_298(txt, i_args);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*_"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")("));
        txt = Tpl.writeText(txt, i_typelist);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") = ("));
        txt = Tpl.writeText(txt, i_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*)("));
        txt = Tpl.writeText(txt, i_typelist);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_299;

public function functionArg
  input Tpl.Text txt;
  input SimCode.Variable i_var;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := fun_299(txt, i_var);
  out_i_varDecls := i_varDecls;
end functionArg;

protected function lm_301
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_varInits, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_varInits, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_varInits) = lm_301(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_varInits )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_varInits) = lm_301(txt, rest, i_varDecls, i_varInits);
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end lm_301;

protected function fun_302
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input Tpl.Text in_i_instDimsInit;
  input DAE.ExpType in_i_var_ty;
  input DAE.ComponentRef in_i_var_name;
  input Integer in_i_i;
  input String in_i_dest;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varInits) :=
  matchcontinue(in_txt, in_i_instDims, in_i_instDimsInit, in_i_var_ty, in_i_var_name, in_i_i, in_i_dest, in_i_var, in_i_varInits)
    local
      Tpl.Text txt;
      Tpl.Text i_instDimsInit;
      DAE.ExpType i_var_ty;
      DAE.ComponentRef i_var_name;
      Integer i_i;
      String i_dest;
      SimCode.Variable i_var;
      Tpl.Text i_varInits;

    case ( txt,
           {},
           _,
           _,
           i_var_name,
           i_i,
           i_dest,
           i_var,
           i_varInits )
      equation
        i_varInits = initRecordMembers(i_varInits, i_var);
        txt = Tpl.writeStr(txt, i_dest);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varInits);

    case ( txt,
           i_instDims,
           i_instDimsInit,
           i_var_ty,
           i_var_name,
           i_i,
           i_dest,
           _,
           i_varInits )
      local
        list<DAE.Exp> i_instDims;
        Integer ret_0;
      equation
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("alloc_"));
        i_varInits = expTypeShort(i_varInits, i_var_ty);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING("_array(&"));
        i_varInits = Tpl.writeStr(i_varInits, i_dest);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(".targ"));
        i_varInits = Tpl.writeStr(i_varInits, intString(i_i));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        ret_0 = listLength(i_instDims);
        i_varInits = Tpl.writeStr(i_varInits, intString(ret_0));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(", "));
        i_varInits = Tpl.writeText(i_varInits, i_instDimsInit);
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_STRING(");"));
        i_varInits = Tpl.writeTok(i_varInits, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, i_var_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data(&"));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, i_dest);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varInits);
  end matchcontinue;
end fun_302;

public function varOutput
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input String in_i_dest;
  input Integer in_i_i;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_varInits;
algorithm
  (out_txt, out_i_varDecls, out_i_varInits) :=
  matchcontinue(in_txt, in_i_var, in_i_dest, in_i_i, in_i_varDecls, in_i_varInits)
    local
      Tpl.Text txt;
      String i_dest;
      Integer i_i;
      Tpl.Text i_varDecls;
      Tpl.Text i_varInits;

    case ( txt,
           (i_var as SimCode.VARIABLE(instDims = i_instDims, name = i_var_name, ty = i_var_ty)),
           i_dest,
           i_i,
           i_varDecls,
           i_varInits )
      local
        DAE.ExpType i_var_ty;
        DAE.ComponentRef i_var_name;
        list<DAE.Exp> i_instDims;
        SimCode.Variable i_var;
        Tpl.Text i_instDimsInit;
      equation
        i_instDimsInit = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_instDimsInit, i_varDecls, i_varInits) = lm_301(i_instDimsInit, i_instDims, i_varDecls, i_varInits);
        i_instDimsInit = Tpl.popIter(i_instDimsInit);
        (txt, i_varInits) = fun_302(txt, i_instDims, i_instDimsInit, i_var_ty, i_var_name, i_i, i_dest, i_var, i_varInits);
      then (txt, i_varDecls, i_varInits);

    case ( txt,
           _,
           _,
           _,
           i_varDecls,
           i_varInits )
      then (txt, i_varDecls, i_varInits);
  end matchcontinue;
end varOutput;

protected function lm_304
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varName;
algorithm
  (out_txt, out_i_varName) :=
  matchcontinue(in_txt, in_items, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_varName;

    case ( txt,
           {},
           i_varName )
      then (txt, i_varName);

    case ( txt,
           i_v :: rest,
           i_varName )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpVar i_v;
      equation
        (txt, i_varName) = recordMemberInit(txt, i_v, i_varName);
        txt = Tpl.nextIter(txt);
        (txt, i_varName) = lm_304(txt, rest, i_varName);
      then (txt, i_varName);

    case ( txt,
           _ :: rest,
           i_varName )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varName) = lm_304(txt, rest, i_varName);
      then (txt, i_varName);
  end matchcontinue;
end lm_304;

public function initRecordMembers
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(ty = DAE.ET_COMPLEX(complexClassType = i_RECORD, varLst = i_ty_varLst), name = i_name) )
      local
        DAE.ComponentRef i_name;
        list<DAE.ExpVar> i_ty_varLst;
        ClassInf.State i_RECORD;
        Tpl.Text i_varName;
      equation
        i_varName = crefStr(emptyTxt, i_name);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varName) = lm_304(txt, i_ty_varLst, i_varName);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end initRecordMembers;

protected function fun_306
  input Tpl.Text in_txt;
  input Option<Integer> in_i_dim;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_dim)
    local
      Tpl.Text txt;

    case ( txt,
           SOME(i_d) )
      local
        Integer i_d;
      equation
        txt = Tpl.writeStr(txt, intString(i_d));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then txt;
  end matchcontinue;
end fun_306;

protected function lm_307
  input Tpl.Text in_txt;
  input list<Option<Integer>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      local
        list<Option<Integer>> rest;
        Option<Integer> i_dim;
      equation
        txt = fun_306(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_307(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Option<Integer>> rest;
      equation
        txt = lm_307(txt, rest);
      then txt;
  end matchcontinue;
end lm_307;

protected function fun_308
  input Tpl.Text in_txt;
  input DAE.ExpVar in_i_v;
  input Tpl.Text in_i_varName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_v, in_i_varName)
    local
      Tpl.Text txt;
      Tpl.Text i_varName;

    case ( txt,
           DAE.COMPLEX_VAR(tp = (i_tp as DAE.ET_ARRAY(arrayDimensions = i_tp_arrayDimensions)), name = i_name),
           i_varName )
      local
        String i_name;
        list<Option<Integer>> i_tp_arrayDimensions;
        DAE.ExpType i_tp;
        Integer ret_2;
        Tpl.Text i_dims;
        Tpl.Text i_arrayType;
      equation
        i_arrayType = expType(emptyTxt, i_tp, true);
        i_dims = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_dims = lm_307(i_dims, i_tp_arrayDimensions);
        i_dims = Tpl.popIter(i_dims);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("alloc_"));
        txt = Tpl.writeText(txt, i_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeText(txt, i_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = listLength(i_tp_arrayDimensions);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dims);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_308;

public function recordMemberInit
  input Tpl.Text txt;
  input DAE.ExpVar i_v;
  input Tpl.Text i_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varName;
algorithm
  out_txt := fun_308(txt, i_v, i_varName);
  out_i_varName := i_varName;
end recordMemberInit;

public function extVarName
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt := crefStr(txt, i_cr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_ext"));
end extVarName;

protected function fun_311
  input Tpl.Text in_txt;
  input String in_i_language;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Function in_i_fun;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_language, in_i_varDecls, in_i_preExp, in_i_fun)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Function i_fun;

    case ( txt,
           "C",
           i_varDecls,
           i_preExp,
           i_fun )
      equation
        (txt, i_preExp, i_varDecls) = extFunCallC(txt, i_fun, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           "FORTRAN 77",
           i_varDecls,
           i_preExp,
           i_fun )
      equation
        (txt, i_preExp, i_varDecls) = extFunCallF77(txt, i_fun, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_311;

public function extFunCall
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fun;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_fun, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_fun as SimCode.EXTERNAL_FUNCTION(language = i_language)),
           i_preExp,
           i_varDecls )
      local
        String i_language;
        SimCode.Function i_fun;
      equation
        (txt, i_varDecls, i_preExp) = fun_311(txt, i_language, i_varDecls, i_preExp, i_fun);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCall;

protected function lm_313
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_preExp, i_varDecls) = extArg(txt, i_arg, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_313(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_313(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_313;

protected function fun_314
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c) )
      local
        DAE.ComponentRef i_c;
      equation
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_314;

protected function lm_315
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_arg :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_varDecls) = extFunCallVardecl(txt, i_arg, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_315(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls) = lm_315(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_315;

protected function fun_316
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extReturn, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)),
           i_varDecls )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        (txt, i_varDecls) = extFunCallVardecl(txt, i_extReturn, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_316;

protected function lm_317
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunCallVarcopy(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_317(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_317(txt, rest);
      then txt;
  end matchcontinue;
end lm_317;

protected function fun_318
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)) )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        txt = extFunCallVarcopy(txt, i_extReturn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_318;

public function extFunCallC
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fun;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_fun, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(extArgs = i_extArgs, extReturn = i_extReturn, extName = i_extName),
           i_preExp,
           i_varDecls )
      local
        String i_extName;
        SimCode.SimExtArg i_extReturn;
        list<SimCode.SimExtArg> i_extArgs;
        Tpl.Text i_returnAssign;
        Tpl.Text i_args;
      equation
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_args, i_varDecls, i_preExp) = lm_313(i_args, i_extArgs, i_varDecls, i_preExp);
        i_args = Tpl.popIter(i_args);
        i_returnAssign = fun_314(emptyTxt, i_extReturn);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_315(txt, i_extArgs, i_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        (txt, i_varDecls) = fun_316(txt, i_extReturn, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_returnAssign);
        txt = Tpl.writeStr(txt, i_extName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_317(txt, i_extArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_318(txt, i_extReturn);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCallC;

protected function lm_320
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_preExp, i_varDecls) = extArgF77(txt, i_arg, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_320(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_320(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_320;

protected function fun_321
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c) )
      local
        DAE.ComponentRef i_c;
      equation
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_321;

protected function lm_322
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_arg :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        (txt, i_varDecls) = extFunCallVardeclF77(txt, i_arg, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_322(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<SimCode.SimExtArg> rest;
      equation
        (txt, i_varDecls) = lm_322(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_322;

protected function fun_323
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extReturn, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)),
           i_varDecls )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        (txt, i_varDecls) = extFunCallVardeclF77(txt, i_extReturn, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_323;

protected function lm_324
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_arg :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_arg;
      equation
        (txt, i_preExp, i_varDecls) = extFunCallBiVarF77(txt, i_arg, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_324(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_324(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_324;

protected function lm_325
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      local
        list<SimCode.SimExtArg> rest;
        SimCode.SimExtArg i_arg;
      equation
        txt = extFunCallVarcopyF77(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_325(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimExtArg> rest;
      equation
        txt = lm_325(txt, rest);
      then txt;
  end matchcontinue;
end lm_325;

protected function fun_326
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_extReturn)
    local
      Tpl.Text txt;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)) )
      local
        SimCode.SimExtArg i_extReturn;
      equation
        txt = extFunCallVarcopyF77(txt, i_extReturn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_326;

public function extFunCallF77
  input Tpl.Text in_txt;
  input SimCode.Function in_i_fun;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_fun, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(extArgs = i_extArgs, extReturn = i_extReturn, biVars = i_biVars, extName = i_extName),
           i_preExp,
           i_varDecls )
      local
        String i_extName;
        list<SimCode.Variable> i_biVars;
        SimCode.SimExtArg i_extReturn;
        list<SimCode.SimExtArg> i_extArgs;
        Tpl.Text i_returnAssign;
        Tpl.Text i_args;
      equation
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_args, i_varDecls, i_preExp) = lm_320(i_args, i_extArgs, i_varDecls, i_preExp);
        i_args = Tpl.popIter(i_args);
        i_returnAssign = fun_321(emptyTxt, i_extReturn);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_322(txt, i_extArgs, i_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        (txt, i_varDecls) = fun_323(txt, i_extReturn, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_324(txt, i_biVars, i_varDecls, i_preExp);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_returnAssign);
        txt = Tpl.writeStr(txt, i_extName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_("));
        txt = Tpl.writeText(txt, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_325(txt, i_extArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_326(txt, i_extReturn);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCallF77;

protected function fun_328
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input DAE.ComponentRef in_i_c;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ty, in_i_c, in_i_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_STRING(),
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_ty,
           i_c,
           i_varDecls )
      local
        DAE.ExpType i_ty;
      equation
        i_varDecls = extType(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = crefStr(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING("_ext;"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext = ("));
        txt = extType(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);
  end matchcontinue;
end fun_328;

protected function fun_329
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ComponentRef in_i_c;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_oi, in_i_c, in_i_ty, in_i_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;
      Tpl.Text i_varDecls;

    case ( txt,
           0,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_c,
           i_ty,
           i_varDecls )
      equation
        i_varDecls = extType(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);
  end matchcontinue;
end fun_329;

public function extFunCallVardecl
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_arg, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(isInput = true, isArray = false, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
      equation
        (txt, i_varDecls) = fun_328(txt, i_ty, i_c, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = false, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Integer i_oi;
      equation
        (txt, i_varDecls) = fun_329(txt, i_oi, i_c, i_ty, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end extFunCallVardecl;

protected function fun_331
  input Tpl.Text in_txt;
  input Boolean in_i_ia;
  input DAE.ComponentRef in_i_c;
  input Integer in_i_oi;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ia, in_i_c, in_i_oi, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      Integer i_oi;
      DAE.ExpType i_ty;

    case ( txt,
           false,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           i_c,
           i_oi,
           i_ty )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_to_f77(&out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_331;

protected function fun_332
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input Boolean in_i_ia;
  input DAE.ComponentRef in_i_c;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_oi, in_i_ia, in_i_c, in_i_ty, in_i_varDecls)
    local
      Tpl.Text txt;
      Boolean i_ia;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;
      Tpl.Text i_varDecls;

    case ( txt,
           0,
           _,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_oi,
           i_ia,
           i_c,
           i_ty,
           i_varDecls )
      local
        Integer i_oi;
      equation
        i_varDecls = expTypeArrayIf(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        txt = fun_331(txt, i_ia, i_c, i_oi, i_ty);
      then (txt, i_varDecls);
  end matchcontinue;
end fun_332;

public function extFunCallVardeclF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_arg, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(isInput = true, isArray = true, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
      equation
        i_varDecls = expTypeArrayIf(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_to_f77(&"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = i_ia, type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Boolean i_ia;
        Integer i_oi;
      equation
        (txt, i_varDecls) = fun_332(txt, i_oi, i_ia, i_c, i_ty, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(type_ = i_ty, cref = i_c),
           i_varDecls )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
      equation
        i_varDecls = expTypeArrayIf(i_varDecls, i_ty);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_c);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end extFunCallVardeclF77;

protected function fun_334
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_value;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_var__name;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_value, in_i_varDecls, in_i_preExp, in_i_var__name)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      Tpl.Text i_var__name;

    case ( txt,
           SOME(i_v),
           i_varDecls,
           i_preExp,
           i_var__name )
      local
        DAE.Exp i_v;
      equation
        txt = Tpl.writeText(txt, i_var__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_v, SimCode.contextFunction, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_334;

protected function lm_335
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;

    case ( txt,
           {},
           i_varDecls,
           i_preExp )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_335(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_335(txt, rest, i_varDecls, i_preExp);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_335;

protected function fun_336
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input DAE.ComponentRef in_i_name;
  input Tpl.Text in_i_instDimsInit;
  input Tpl.Text in_i_var__name;
  input Tpl.Text in_i_preExp;
  input DAE.ExpType in_i_var_ty;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_instDims, in_i_name, in_i_instDimsInit, in_i_var__name, in_i_preExp, in_i_var_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_name;
      Tpl.Text i_instDimsInit;
      Tpl.Text i_var__name;
      Tpl.Text i_preExp;
      DAE.ExpType i_var_ty;

    case ( txt,
           {},
           _,
           _,
           _,
           i_preExp,
           _ )
      then (txt, i_preExp);

    case ( txt,
           i_instDims,
           i_name,
           i_instDimsInit,
           i_var__name,
           i_preExp,
           i_var_ty )
      local
        list<DAE.Exp> i_instDims;
        Integer ret_1;
        Tpl.Text i_type;
      equation
        i_type = expTypeArray(emptyTxt, i_var_ty);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var__name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        ret_1 = listLength(i_instDims);
        i_preExp = Tpl.writeStr(i_preExp, intString(ret_1));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_instDimsInit);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("convert_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_to_f77(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var__name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = extVarName(i_preExp, i_name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
      then (txt, i_preExp);
  end matchcontinue;
end fun_336;

public function extFunCallBiVarF77
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_var, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name, value = i_value, instDims = i_instDims, ty = i_var_ty)),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_var_ty;
        list<DAE.Exp> i_instDims;
        Option<DAE.Exp> i_value;
        DAE.ComponentRef i_name;
        SimCode.Variable i_var;
        Tpl.Text i_instDimsInit;
        Tpl.Text i_defaultValue;
        Tpl.Text i_var__name;
      equation
        i_var__name = crefStr(emptyTxt, i_name);
        i_varDecls = varType(i_varDecls, i_var);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = Tpl.writeText(i_varDecls, i_var__name);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        i_varDecls = varType(i_varDecls, i_var);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(" "));
        i_varDecls = extVarName(i_varDecls, i_name);
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_STRING(";"));
        i_varDecls = Tpl.writeTok(i_varDecls, Tpl.ST_NEW_LINE());
        (i_defaultValue, i_varDecls, i_preExp) = fun_334(emptyTxt, i_value, i_varDecls, i_preExp, i_var__name);
        i_preExp = Tpl.writeText(i_preExp, i_defaultValue);
        i_instDimsInit = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_instDimsInit, i_varDecls, i_preExp) = lm_335(i_instDimsInit, i_instDims, i_varDecls, i_preExp);
        i_instDimsInit = Tpl.popIter(i_instDimsInit);
        (txt, i_preExp) = fun_336(txt, i_instDims, i_name, i_instDimsInit, i_var__name, i_preExp, i_var_ty);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extFunCallBiVarF77;

protected function fun_338
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ComponentRef in_i_c;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_c, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;

    case ( txt,
           0,
           _,
           _ )
      then txt;

    case ( txt,
           i_oi,
           i_c,
           i_ty )
      local
        Integer i_oi;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = ("));
        txt = expTypeModelica(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext;"));
      then txt;
  end matchcontinue;
end fun_338;

public function extFunCallVarcopy
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_arg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = false, type_ = i_ty, cref = i_c) )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Integer i_oi;
      equation
        txt = fun_338(txt, i_oi, i_c, i_ty);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunCallVarcopy;

protected function fun_340
  input Tpl.Text in_txt;
  input Boolean in_i_ai;
  input Tpl.Text in_i_ext__name;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_outarg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ai, in_i_ext__name, in_i_ty, in_i_outarg)
    local
      Tpl.Text txt;
      Tpl.Text i_ext__name;
      DAE.ExpType i_ty;
      Tpl.Text i_outarg;

    case ( txt,
           false,
           i_ext__name,
           i_ty,
           i_outarg )
      equation
        txt = Tpl.writeText(txt, i_outarg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = ("));
        txt = expTypeModelica(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = Tpl.writeText(txt, i_ext__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           true,
           i_ext__name,
           i_ty,
           i_outarg )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_from_f77(&"));
        txt = Tpl.writeText(txt, i_ext__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_outarg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_340;

protected function fun_341
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ExpType in_i_ty;
  input Boolean in_i_ai;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_ty, in_i_ai, in_i_c)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;
      Boolean i_ai;
      DAE.ComponentRef i_c;

    case ( txt,
           0,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           i_oi,
           i_ty,
           i_ai,
           i_c )
      local
        Integer i_oi;
        Tpl.Text i_ext__name;
        Tpl.Text i_outarg;
      equation
        i_outarg = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("out.targ"));
        i_outarg = Tpl.writeStr(i_outarg, intString(i_oi));
        i_ext__name = crefStr(emptyTxt, i_c);
        i_ext__name = Tpl.writeTok(i_ext__name, Tpl.ST_STRING("_ext"));
        txt = fun_340(txt, i_ai, i_ext__name, i_ty, i_outarg);
      then txt;
  end matchcontinue;
end fun_341;

public function extFunCallVarcopyF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_arg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_arg)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = i_ai, type_ = i_ty, cref = i_c) )
      local
        DAE.ComponentRef i_c;
        DAE.ExpType i_ty;
        Boolean i_ai;
        Integer i_oi;
      equation
        txt = fun_341(txt, i_oi, i_ty, i_ai, i_c);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunCallVarcopyF77;

protected function fun_343
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           0,
           i_c )
      equation
        txt = crefStr(txt, i_c);
      then txt;

    case ( txt,
           i_oi,
           _ )
      local
        Integer i_oi;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
      then txt;
  end matchcontinue;
end fun_343;

protected function fun_344
  input Tpl.Text in_txt;
  input Integer in_i_oi;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi)
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
end fun_344;

protected function fun_345
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_t)
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
end fun_345;

protected function fun_346
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input DAE.ExpType in_i_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_t)
    local
      Tpl.Text txt;
      DAE.ExpType i_t;

    case ( txt,
           0,
           i_t )
      equation
        txt = fun_345(txt, i_t);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_346;

protected function fun_347
  input Tpl.Text in_txt;
  input Integer in_i_outputIndex;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_outputIndex, in_i_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           0,
           i_c )
      equation
        txt = crefStr(txt, i_c);
      then txt;

    case ( txt,
           i_outputIndex,
           _ )
      local
        Integer i_outputIndex;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_outputIndex));
      then txt;
  end matchcontinue;
end fun_347;

public function extArg
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extArg, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, outputIndex = i_oi, isArray = true, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        Integer i_oi;
        DAE.ComponentRef i_c;
        Tpl.Text i_shortTypeStr;
        Tpl.Text i_name;
      equation
        i_name = fun_343(emptyTxt, i_oi, i_c);
        i_shortTypeStr = expTypeShort(emptyTxt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("data_of_"));
        txt = Tpl.writeText(txt, i_shortTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&("));
        txt = Tpl.writeText(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = i_ii, outputIndex = i_oi, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        Integer i_oi;
        Boolean i_ii;
        DAE.ComponentRef i_c;
        Tpl.Text i_suffix;
        Tpl.Text i_prefix;
      equation
        i_prefix = fun_344(emptyTxt, i_oi);
        i_suffix = fun_346(emptyTxt, i_oi, i_t);
        txt = Tpl.writeText(txt, i_prefix);
        txt = crefStr(txt, i_c);
        txt = Tpl.writeText(txt, i_suffix);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGEXP(exp = i_exp),
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, type_ = i_type__, outputIndex = i_outputIndex, exp = i_exp),
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
        Integer i_outputIndex;
        DAE.ExpType i_type__;
        DAE.ComponentRef i_c;
        Tpl.Text i_dim;
        Tpl.Text i_name;
        Tpl.Text i_typeStr;
      equation
        i_typeStr = expTypeShort(emptyTxt, i_type__);
        i_name = fun_347(emptyTxt, i_outputIndex, i_c);
        (i_dim, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size_of_dimension_"));
        txt = Tpl.writeText(txt, i_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array("));
        txt = Tpl.writeText(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dim);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extArg;

protected function fun_349
  input Tpl.Text in_txt;
  input Boolean in_i_ia;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ia)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_349;

protected function fun_350
  input Tpl.Text in_txt;
  input Integer in_i_oi;
  input Boolean in_i_ia;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_oi, in_i_ia)
    local
      Tpl.Text txt;
      Boolean i_ia;

    case ( txt,
           0,
           i_ia )
      equation
        txt = fun_349(txt, i_ia);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_350;

public function extArgF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_i_extArg;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_extArg, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isArray = true, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        DAE.ComponentRef i_c;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("data_of_"));
        txt = expTypeShort(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&("));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isArray = i_ia, outputIndex = i_oi, type_ = i_t),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_t;
        Integer i_oi;
        Boolean i_ia;
        DAE.ComponentRef i_c;
        Tpl.Text i_suffix;
      equation
        i_suffix = fun_350(emptyTxt, i_oi, i_ia);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = crefStr(txt, i_c);
        txt = Tpl.writeText(txt, i_suffix);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGEXP(exp = i_exp),
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, exp = i_exp, type_ = i_type__),
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_type__;
        DAE.Exp i_exp;
        DAE.ComponentRef i_c;
        Tpl.Text i_size__call;
        Tpl.Text i_dim;
        Tpl.Text i_sizeVar;
        Tpl.Text i_sizeVarName;
      equation
        i_sizeVarName = tempSizeVarName(emptyTxt, i_c, i_exp);
        (i_sizeVar, i_varDecls) = tempDecl(emptyTxt, "int", i_varDecls);
        (i_dim, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, SimCode.contextFunction, i_preExp, i_varDecls);
        i_size__call = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("size_of_dimension_"));
        i_size__call = expTypeShort(i_size__call, i_type__);
        i_size__call = Tpl.writeTok(i_size__call, Tpl.ST_STRING("_array"));
        i_preExp = Tpl.writeText(i_preExp, i_sizeVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_size__call);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = crefStr(i_preExp, i_c);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dim);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = Tpl.writeText(txt, i_sizeVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end extArgF77;

protected function fun_352
  input Tpl.Text in_txt;
  input DAE.Exp in_i_indices;
  input DAE.ComponentRef in_i_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_indices, in_i_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           DAE.ICONST(integer = i_integer),
           i_c )
      local
        Integer i_integer;
      equation
        txt = crefStr(txt, i_c);
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
end fun_352;

public function tempSizeVarName
  input Tpl.Text txt;
  input DAE.ComponentRef i_c;
  input DAE.Exp i_indices;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_352(txt, i_indices, i_c);
end tempSizeVarName;

protected function lm_354
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, SimCode.contextFunction, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_354(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_354(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_354;

public function funStatement
  input Tpl.Text in_txt;
  input SimCode.Statement in_i_stmt;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SimCode.ALGORITHM(statementLst = i_statementLst),
           i_varDecls )
      local
        list<DAE.Statement> i_statementLst;
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_354(txt, i_statementLst, i_varDecls);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED FUN STATEMENT"));
      then (txt, i_varDecls);
  end matchcontinue;
end funStatement;

public function algStatement
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_s as DAE.STMT_ASSIGN(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtAssign(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_ASSIGN_ARR(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtAssignArr(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_TUPLE_ASSIGN(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtTupleAssign(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_IF(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtIf(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_FOR(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtFor(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_WHILE(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtWhile(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_ASSERT(cond = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtAssert(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_WHEN(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtWhen(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_MATCHCASES(caseStmt = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtMatchcases(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_BREAK()),
           _,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_TRY(tryBody = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtTry(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_CATCH(catchBody = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtCatch(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_THROW()),
           _,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("throw 1;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_RETURN()),
           _,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("goto _return;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_NORETCALL(exp = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtNoretcall(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED ALG STATEMENT"));
      then (txt, i_varDecls);
  end matchcontinue;
end algStatement;

public function algStmtAssign
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = DAE.WILD()), exp = i_e),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_e;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
      then (txt, i_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = (i_exp1 as DAE.CREF(componentRef = _)), exp = i_exp),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_exp;
        DAE.Exp i_exp1;
        Tpl.Text i_expPart;
        Tpl.Text i_varPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_varPart, i_preExp, i_varDecls) = scalarLhsCref(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_varPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = i_exp1, exp = i_exp),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_exp;
        DAE.Exp i_exp1;
        Tpl.Text i_expPart2;
        Tpl.Text i_expPart1;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_expPart2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_expPart1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_expPart2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtAssign;

protected function fun_358
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_ispec;
  input DAE.ComponentRef in_i_cref;
  input Tpl.Text in_i_expPart;
  input DAE.ExpType in_i_t;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it, in_i_ispec, in_i_cref, in_i_expPart, in_i_t, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_ispec;
      DAE.ComponentRef i_cref;
      Tpl.Text i_expPart;
      DAE.ExpType i_t;
      Tpl.Text i_preExp;

    case ( txt,
           "",
           _,
           i_cref,
           i_expPart,
           i_t,
           i_preExp )
      equation
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeArray(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_data(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = arrayCrefStr(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           i_ispec,
           i_cref,
           i_expPart,
           i_t,
           i_preExp )
      equation
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("indexed_assign_"));
        txt = expTypeArray(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = arrayCrefStr(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_ispec);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_358;

public function algStmtAssignArr
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_ASSIGN_ARR(exp = i_e, componentRef = i_cref, type_ = i_t),
           i_context,
           i_varDecls )
      local
        DAE.ExpType i_t;
        DAE.ComponentRef i_cref;
        DAE.Exp i_e;
        String str_3;
        Tpl.Text i_ispec;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_ispec, i_preExp, i_varDecls) = indexSpecFromCref(emptyTxt, i_cref, i_context, i_preExp, i_varDecls);
        str_3 = Tpl.textString(i_ispec);
        txt = fun_358(txt, str_3, i_ispec, i_cref, i_expPart, i_t, i_preExp);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtAssignArr;

protected function lm_360
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_retStruct;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_retStruct, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_retStruct;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           (i_cr as DAE.CREF(componentRef = _)) :: rest,
           i_retStruct,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_cr;
        Integer i_i1;
        Tpl.Text i_lhsStr;
      equation
        i_i1 = Tpl.getIteri_i1(txt);
        (i_lhsStr, i_preExp, i_varDecls) = scalarLhsCref(emptyTxt, i_cr, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_retStruct);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(i_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_360(txt, rest, i_retStruct, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_retStruct,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_360(txt, rest, i_retStruct, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_360;

public function algStmtTupleAssign
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_TUPLE_ASSIGN(exp = (i_exp as DAE.CALL(path = _)), expExpLst = i_expExpLst),
           i_context,
           i_varDecls )
      local
        list<DAE.Exp> i_expExpLst;
        DAE.Exp i_exp;
        Tpl.Text i_retStruct;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_retStruct, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_360(txt, i_expExpLst, i_retStruct, i_varDecls, i_preExp, i_context);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtTupleAssign;

protected function lm_362
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_362(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_362(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_362;

public function algStmtIf
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_IF(exp = i_exp, statementLst = i_statementLst, else_ = i_else__),
           i_context,
           i_varDecls )
      local
        DAE.Else i_else__;
        list<DAE.Statement> i_statementLst;
        DAE.Exp i_exp;
        Tpl.Text i_condExp;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_condExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, i_condExp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_362(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        (txt, i_varDecls) = elseExpr(txt, i_else__, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtIf;

public function algStmtFor
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_s as DAE.STMT_FOR(exp = (i_rng as DAE.RANGE(ty = _)))),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_rng;
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtForRange(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           (i_s as DAE.STMT_FOR(type_ = _)),
           i_context,
           i_varDecls )
      local
        DAE.Statement i_s;
      equation
        (txt, i_varDecls) = algStmtForGeneric(txt, i_s, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtFor;

protected function lm_365
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_365(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_365(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_365;

public function algStmtForRange
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_FOR(exp = (i_rng as DAE.RANGE(ty = _)), type_ = i_type__, iterIsArray = i_iterIsArray, statementLst = i_statementLst, ident = i_ident),
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        list<DAE.Statement> i_statementLst;
        Boolean i_iterIsArray;
        DAE.ExpType i_type__;
        DAE.Exp i_rng;
        Tpl.Text i_stmtStr;
        Tpl.Text i_identTypeShort;
        Tpl.Text i_identType;
      equation
        i_identType = expType(emptyTxt, i_type__, i_iterIsArray);
        i_identTypeShort = expTypeShort(emptyTxt, i_type__);
        i_stmtStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_stmtStr, i_varDecls) = lm_365(i_stmtStr, i_statementLst, i_varDecls, i_context);
        i_stmtStr = Tpl.popIter(i_stmtStr);
        (txt, i_stmtStr, i_varDecls) = algStmtForRange_impl(txt, i_rng, i_ident, Tpl.textString(i_identType), Tpl.textString(i_identTypeShort), i_stmtStr, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtForRange;

protected function fun_367
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_expOption;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_expOption, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           SOME(i_eo),
           i_varDecls,
           i_preExp,
           i_context )
      local
        DAE.Exp i_eo;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_eo, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1)"));
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_367;

protected function fun_368
  input Tpl.Text in_txt;
  input DAE.Exp in_i_range;
  input Absyn.Ident in_i_iterator;
  input String in_i_type;
  input String in_i_shortType;
  input Tpl.Text in_i_body;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_range, in_i_iterator, in_i_type, in_i_shortType, in_i_body, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      Absyn.Ident i_iterator;
      String i_type;
      String i_shortType;
      Tpl.Text i_body;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.RANGE(exp = i_exp, expOption = i_expOption, range = i_range),
           i_iterator,
           i_type,
           i_shortType,
           i_body,
           i_context,
           i_varDecls )
      local
        DAE.Exp i_range;
        Option<DAE.Exp> i_expOption;
        DAE.Exp i_exp;
        Tpl.Text i_stopValue;
        Tpl.Text i_stepValue;
        Tpl.Text i_startValue;
        Tpl.Text i_preExp;
        Tpl.Text i_stopVar;
        Tpl.Text i_stepVar;
        Tpl.Text i_startVar;
        Tpl.Text i_stateVar;
        Tpl.Text i_iterName;
      equation
        i_iterName = contextIteratorName(emptyTxt, i_iterator, i_context);
        (i_stateVar, i_varDecls) = tempDecl(emptyTxt, "state", i_varDecls);
        (i_startVar, i_varDecls) = tempDecl(emptyTxt, i_type, i_varDecls);
        (i_stepVar, i_varDecls) = tempDecl(emptyTxt, i_type, i_varDecls);
        (i_stopVar, i_varDecls) = tempDecl(emptyTxt, i_type, i_varDecls);
        i_preExp = emptyTxt;
        (i_startValue, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (i_stepValue, i_varDecls, i_preExp) = fun_367(emptyTxt, i_expOption, i_varDecls, i_preExp, i_context);
        (i_stopValue, i_preExp, i_varDecls) = daeExp(emptyTxt, i_range, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_startVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_startValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, i_stepVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_stepValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, i_stopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_stopValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("for("));
        txt = Tpl.writeStr(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, i_startValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; in_range_"));
        txt = Tpl.writeStr(txt, i_shortType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_startVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_stopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("); "));
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" += "));
        txt = Tpl.writeText(txt, i_stepVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" = get_memory_state();\n"));
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_368;

public function algStmtForRange_impl
  input Tpl.Text txt;
  input DAE.Exp i_range;
  input Absyn.Ident i_iterator;
  input String i_type;
  input String i_shortType;
  input Tpl.Text i_body;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_body;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_368(txt, i_range, i_iterator, i_type, i_shortType, i_body, i_context, i_varDecls);
  out_i_body := i_body;
end algStmtForRange_impl;

protected function lm_370
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_370(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_370(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_370;

public function algStmtForGeneric
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_FOR(type_ = i_type__, iterIsArray = i_iterIsArray, statementLst = i_statementLst, exp = i_exp, ident = i_ident),
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        DAE.Exp i_exp;
        list<DAE.Statement> i_statementLst;
        Boolean i_iterIsArray;
        DAE.ExpType i_type__;
        Tpl.Text i_stmtStr;
        Tpl.Text i_arrayType;
        Tpl.Text i_iterType;
      equation
        i_iterType = expType(emptyTxt, i_type__, i_iterIsArray);
        i_arrayType = expTypeArray(emptyTxt, i_type__);
        i_stmtStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_stmtStr, i_varDecls) = lm_370(i_stmtStr, i_statementLst, i_varDecls, i_context);
        i_stmtStr = Tpl.popIter(i_stmtStr);
        (txt, i_stmtStr, i_varDecls) = algStmtForGeneric_impl(txt, i_exp, i_ident, Tpl.textString(i_iterType), Tpl.textString(i_arrayType), i_iterIsArray, i_stmtStr, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtForGeneric;

protected function fun_372
  input Tpl.Text in_txt;
  input Boolean in_i_iterIsArray;
  input Tpl.Text in_i_ivar;
  input String in_i_type;
  input Tpl.Text in_i_tvar;
  input Tpl.Text in_i_evar;
  input String in_i_arrayType;
  input Tpl.Text in_i_iterName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_iterIsArray, in_i_ivar, in_i_type, in_i_tvar, in_i_evar, in_i_arrayType, in_i_iterName)
    local
      Tpl.Text txt;
      Tpl.Text i_ivar;
      String i_type;
      Tpl.Text i_tvar;
      Tpl.Text i_evar;
      String i_arrayType;
      Tpl.Text i_iterName;

    case ( txt,
           false,
           _,
           _,
           i_tvar,
           i_evar,
           i_arrayType,
           i_iterName )
      equation
        txt = Tpl.writeText(txt, i_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = *("));
        txt = Tpl.writeStr(txt, i_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_element_addr1(&"));
        txt = Tpl.writeText(txt, i_evar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", 1, "));
        txt = Tpl.writeText(txt, i_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then txt;

    case ( txt,
           _,
           i_ivar,
           i_type,
           i_tvar,
           i_evar,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("simple_index_alloc_"));
        txt = Tpl.writeStr(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1(&"));
        txt = Tpl.writeText(txt, i_evar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_ivar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_372;

public function algStmtForGeneric_impl
  input Tpl.Text txt;
  input DAE.Exp i_exp;
  input Absyn.Ident i_iterator;
  input String i_type;
  input String i_arrayType;
  input Boolean i_iterIsArray;
  input Tpl.Text i_body;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_body;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_stmtStuff;
  Tpl.Text i_evar;
  Tpl.Text i_preExp;
  Tpl.Text i_ivar;
  Tpl.Text i_tvar;
  Tpl.Text i_stateVar;
  Tpl.Text i_iterName;
algorithm
  i_iterName := contextIteratorName(emptyTxt, i_iterator, i_context);
  (i_stateVar, out_i_varDecls) := tempDecl(emptyTxt, "state", i_varDecls);
  (i_tvar, out_i_varDecls) := tempDecl(emptyTxt, "int", out_i_varDecls);
  (i_ivar, out_i_varDecls) := tempDecl(emptyTxt, i_type, out_i_varDecls);
  i_preExp := emptyTxt;
  (i_evar, i_preExp, out_i_varDecls) := daeExp(emptyTxt, i_exp, i_context, i_preExp, out_i_varDecls);
  i_stmtStuff := fun_372(emptyTxt, i_iterIsArray, i_ivar, i_type, i_tvar, i_evar, i_arrayType, i_iterName);
  out_txt := Tpl.writeText(txt, i_preExp);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("{\n"));
  out_txt := Tpl.writeStr(out_txt, i_type);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" "));
  out_txt := Tpl.writeText(out_txt, i_iterName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("for("));
  out_txt := Tpl.writeText(out_txt, i_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" = 1; "));
  out_txt := Tpl.writeText(out_txt, i_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" <= size_of_dimension_"));
  out_txt := Tpl.writeStr(out_txt, i_arrayType);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.writeText(out_txt, i_evar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(", 1); ++"));
  out_txt := Tpl.writeText(out_txt, i_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(") {\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(" = get_memory_state();\n"));
  out_txt := Tpl.writeText(out_txt, i_stmtStuff);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, i_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("restore_memory_state("));
  out_txt := Tpl.writeText(out_txt, i_stateVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(");\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("}\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
  out_i_body := i_body;
end algStmtForGeneric_impl;

protected function lm_374
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_374(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_374(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_374;

public function algStmtWhile
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_WHILE(exp = i_exp, statementLst = i_statementLst),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_statementLst;
        DAE.Exp i_exp;
        Tpl.Text i_var;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_var, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("while (1) {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (!"));
        txt = Tpl.writeText(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") break;\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_374(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtWhile;

public function algStmtAssert
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_ASSERT(cond = i_cond, msg = i_msg),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_msg;
        DAE.Exp i_cond;
        Tpl.Text i_msgVar;
        Tpl.Text i_condVar;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_condVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_cond, i_context, i_preExp, i_varDecls);
        (i_msgVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_msg, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MODELICA_ASSERT("));
        txt = Tpl.writeText(txt, i_condVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_msgVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtAssert;

protected function lm_377
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_doneVar;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_doneVar, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_doneVar;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_e :: rest,
           i_doneVar,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_e;
        Integer i_i0;
        Tpl.Text i_0__;
        Tpl.Text i_preExp;
      equation
        i_i0 = Tpl.getIteri_i0(txt);
        i_preExp = emptyTxt;
        (i_0__, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(i_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(": {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = 1;\n",
                                    "break;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_377(txt, rest, i_doneVar, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_doneVar,
           i_varDecls,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls) = lm_377(txt, rest, i_doneVar, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_377;

public function algStmtMatchcases
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_MATCHCASES(caseStmt = i_caseStmt),
           i_context,
           i_varDecls )
      local
        list<DAE.Exp> i_caseStmt;
        Integer ret_3;
        Tpl.Text i_numCases;
        Tpl.Text i_doneVar;
        Tpl.Text i_loopVar;
      equation
        (i_loopVar, i_varDecls) = tempDecl(emptyTxt, "modelica_integer", i_varDecls);
        (i_doneVar, i_varDecls) = tempDecl(emptyTxt, "modelica_integer", i_varDecls);
        ret_3 = listLength(i_caseStmt);
        i_numCases = Tpl.writeStr(emptyTxt, intString(ret_3));
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = 0;\n",
                                    "for ("
                                }, false));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("=0; 0=="));
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<"));
        txt = Tpl.writeText(txt, i_numCases);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "++) {\n",
                                    "  try {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("switch ("));
        txt = Tpl.writeText(txt, i_loopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_377(txt, i_caseStmt, i_doneVar, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("} /* end matchcontinue switch */\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "  } catch (int i) {\n",
                                    "  }\n",
                                    "} /* end matchcontinue for */\n",
                                    "if (0 == "
                                }, false));
        txt = Tpl.writeText(txt, i_doneVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") throw 1; /* Didn\'t end in a valid state */"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtMatchcases;

protected function lm_379
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_379(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_379(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_379;

public function algStmtTry
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_TRY(tryBody = i_tryBody),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_tryBody;
        Tpl.Text i_body;
      equation
        i_body = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_body, i_varDecls) = lm_379(i_body, i_tryBody, i_varDecls, i_context);
        i_body = Tpl.popIter(i_body);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("try {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtTry;

protected function lm_381
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_381(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_381(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_381;

public function algStmtCatch
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_CATCH(catchBody = i_catchBody),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_catchBody;
        Tpl.Text i_body;
      equation
        i_body = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_body, i_varDecls) = lm_381(i_body, i_catchBody, i_varDecls, i_context);
        i_body = Tpl.popIter(i_body);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("catch (int i) {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtCatch;

public function algStmtNoretcall
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_NORETCALL(exp = i_exp),
           i_context,
           i_varDecls )
      local
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStmtNoretcall;

protected function lm_384
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_384(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_384(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_384;

protected function lm_385
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_idx :: rest )
      local
        list<Integer> rest;
        Integer i_idx;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_idx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        txt = lm_385(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_385(txt, rest);
      then txt;
  end matchcontinue;
end lm_385;

protected function fun_386
  input Tpl.Text in_txt;
  input DAE.Statement in_i_when;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_when, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_when as DAE.STMT_WHEN(statementLst = i_statementLst, elseWhen = i_elseWhen, helpVarIndices = i_helpVarIndices)),
           i_context,
           i_varDecls )
      local
        list<Integer> i_helpVarIndices;
        Option<DAE.Statement> i_elseWhen;
        list<DAE.Statement> i_statementLst;
        DAE.Statement i_when;
        Tpl.Text i_else;
        Tpl.Text i_statements;
        Tpl.Text i_preIf;
      equation
        (i_preIf, i_varDecls) = algStatementWhenPre(emptyTxt, i_when, i_varDecls);
        i_statements = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_statements, i_varDecls) = lm_384(i_statements, i_statementLst, i_varDecls, i_context);
        i_statements = Tpl.popIter(i_statements);
        (i_else, i_varDecls) = algStatementWhenElse(emptyTxt, i_elseWhen, i_varDecls);
        txt = Tpl.writeText(txt, i_preIf);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_385(txt, i_helpVarIndices);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_statements);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, i_else);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_386;

protected function fun_387
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.Statement in_i_when;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_context, in_i_when, in_i_varDecls)
    local
      Tpl.Text txt;
      DAE.Statement i_when;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_context as SimCode.SIMULATION(genDiscrete = true)),
           i_when,
           i_varDecls )
      local
        SimCode.Context i_context;
      equation
        (txt, i_varDecls) = fun_386(txt, i_when, i_context, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_387;

public function algStmtWhen
  input Tpl.Text txt;
  input DAE.Statement i_when;
  input SimCode.Context i_context;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) := fun_387(txt, i_context, i_when, i_varDecls);
end algStmtWhen;

protected function fun_389
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_i_elseWhen;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_elseWhen, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME(i_ew),
           i_varDecls )
      local
        DAE.Statement i_ew;
      equation
        (txt, i_varDecls) = algStatementWhenPre(txt, i_ew, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_389;

protected function fun_390
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_i_when_elseWhen;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_when_elseWhen, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME(i_ew),
           i_varDecls )
      local
        DAE.Statement i_ew;
      equation
        (txt, i_varDecls) = algStatementWhenPre(txt, i_ew, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_390;

protected function fun_391
  input Tpl.Text in_txt;
  input list<Integer> in_i_helpVarIndices;
  input DAE.Exp in_i_when_exp;
  input Tpl.Text in_i_varDecls;
  input Option<DAE.Statement> in_i_when_elseWhen;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_helpVarIndices, in_i_when_exp, in_i_varDecls, in_i_when_elseWhen)
    local
      Tpl.Text txt;
      DAE.Exp i_when_exp;
      Tpl.Text i_varDecls;
      Option<DAE.Statement> i_when_elseWhen;

    case ( txt,
           {i_i},
           i_when_exp,
           i_varDecls,
           i_when_elseWhen )
      local
        Integer i_i;
        Tpl.Text i_res;
        Tpl.Text i_preExp;
        Tpl.Text i_restPre;
      equation
        (i_restPre, i_varDecls) = fun_390(emptyTxt, i_when_elseWhen, i_varDecls);
        i_preExp = emptyTxt;
        (i_res, i_preExp, i_varDecls) = daeExp(emptyTxt, i_when_exp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_res);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, i_restPre);
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls,
           _ )
      then (txt, i_varDecls);
  end matchcontinue;
end fun_391;

public function algStatementWhenPre
  input Tpl.Text in_txt;
  input DAE.Statement in_i_stmt;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.STMT_WHEN(exp = DAE.ARRAY(array = i_el), elseWhen = i_elseWhen, helpVarIndices = i_helpVarIndices),
           i_varDecls )
      local
        list<Integer> i_helpVarIndices;
        Option<DAE.Statement> i_elseWhen;
        list<DAE.Exp> i_el;
        Tpl.Text i_assignments;
        Tpl.Text i_preExp;
        Tpl.Text i_restPre;
      equation
        (i_restPre, i_varDecls) = fun_389(emptyTxt, i_elseWhen, i_varDecls);
        i_preExp = emptyTxt;
        (i_assignments, i_preExp, i_varDecls) = algStatementWhenPreAssigns(emptyTxt, i_el, i_helpVarIndices, i_preExp, i_varDecls);
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_assignments);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, i_restPre);
      then (txt, i_varDecls);

    case ( txt,
           (i_when as DAE.STMT_WHEN(helpVarIndices = i_helpVarIndices, elseWhen = i_when_elseWhen, exp = i_when_exp)),
           i_varDecls )
      local
        DAE.Exp i_when_exp;
        Option<DAE.Statement> i_when_elseWhen;
        list<Integer> i_helpVarIndices;
        DAE.Statement i_when;
      equation
        (txt, i_varDecls) = fun_391(txt, i_helpVarIndices, i_when_exp, i_varDecls, i_when_elseWhen);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStatementWhenPre;

protected function lm_393
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, SimCode.contextSimulationDiscrete, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_393(txt, rest, i_varDecls);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_393(txt, rest, i_varDecls);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_393;

protected function lm_394
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_idx :: rest )
      local
        list<Integer> rest;
        Integer i_idx;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_idx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        txt = lm_394(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Integer> rest;
      equation
        txt = lm_394(txt, rest);
      then txt;
  end matchcontinue;
end lm_394;

public function algStatementWhenElse
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_i_stmt;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_stmt, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;

    case ( txt,
           SOME((i_when as DAE.STMT_WHEN(statementLst = i_when_statementLst, elseWhen = i_when_elseWhen, helpVarIndices = i_when_helpVarIndices))),
           i_varDecls )
      local
        list<Integer> i_when_helpVarIndices;
        Option<DAE.Statement> i_when_elseWhen;
        list<DAE.Statement> i_when_statementLst;
        DAE.Statement i_when;
        Tpl.Text i_elseCondStr;
        Tpl.Text i_else;
        Tpl.Text i_statements;
      equation
        i_statements = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_statements, i_varDecls) = lm_393(i_statements, i_when_statementLst, i_varDecls);
        i_statements = Tpl.popIter(i_statements);
        (i_else, i_varDecls) = algStatementWhenElse(emptyTxt, i_when_elseWhen, i_varDecls);
        i_elseCondStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_elseCondStr = lm_394(i_elseCondStr, i_when_helpVarIndices);
        i_elseCondStr = Tpl.popIter(i_elseCondStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("else if ("));
        txt = Tpl.writeText(txt, i_elseCondStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_statements);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, i_else);
      then (txt, i_varDecls);

    case ( txt,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end algStatementWhenElse;

protected function fun_396
  input Tpl.Text in_txt;
  input list<Integer> in_i_ints;
  input DAE.Exp in_i_firstExp;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input list<DAE.Exp> in_i_restExps;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_ints, in_i_firstExp, in_i_varDecls, in_i_preExp, in_i_restExps)
    local
      Tpl.Text txt;
      DAE.Exp i_firstExp;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      list<DAE.Exp> i_restExps;

    case ( txt,
           i_firstInt :: i_restInts,
           i_firstExp,
           i_varDecls,
           i_preExp,
           i_restExps )
      local
        list<Integer> i_restInts;
        Integer i_firstInt;
        Tpl.Text i_firstExpPart;
        Tpl.Text i_rest;
      equation
        (i_rest, i_preExp, i_varDecls) = algStatementWhenPreAssigns(emptyTxt, i_restExps, i_restInts, i_preExp, i_varDecls);
        (i_firstExpPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_firstExp, SimCode.contextSimulationDiscrete, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_firstInt));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, i_firstExpPart);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, i_rest);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_396;

public function algStatementWhenPreAssigns
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_exps;
  input list<Integer> in_i_ints;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exps, in_i_ints, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      list<Integer> i_ints;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_firstExp :: i_restExps,
           i_ints,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_restExps;
        DAE.Exp i_firstExp;
      equation
        (txt, i_varDecls, i_preExp) = fun_396(txt, i_ints, i_firstExp, i_varDecls, i_preExp, i_restExps);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end algStatementWhenPreAssigns;

public function indexSpecFromCref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cref;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_cref, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CREF_IDENT(subscriptLst = (i_subs as _ :: _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Subscript> i_subs;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhsIndexSpec(txt, i_subs, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end indexSpecFromCref;

protected function lm_399
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_399(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_399(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_399;

protected function lm_400
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDecls;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           _ )
      then (txt, i_varDecls);

    case ( txt,
           i_stmt :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDecls) = algStatement(txt, i_stmt, i_context, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls) = lm_400(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDecls) = lm_400(txt, rest, i_varDecls, i_context);
      then (txt, i_varDecls);
  end matchcontinue;
end lm_400;

public function elseExpr
  input Tpl.Text in_txt;
  input DAE.Else in_i_else__;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_else__, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.NOELSE(),
           _,
           i_varDecls )
      then (txt, i_varDecls);

    case ( txt,
           DAE.ELSEIF(exp = i_exp, statementLst = i_statementLst, else_ = i_else__),
           i_context,
           i_varDecls )
      local
        DAE.Else i_else__;
        list<DAE.Statement> i_statementLst;
        DAE.Exp i_exp;
        Tpl.Text i_condExp;
        Tpl.Text i_preExp;
      equation
        i_preExp = emptyTxt;
        (i_condExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, i_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, i_condExp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_399(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        (txt, i_varDecls) = elseExpr(txt, i_else__, i_context, i_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           DAE.ELSE(statementLst = i_statementLst),
           i_context,
           i_varDecls )
      local
        list<DAE.Statement> i_statementLst;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls) = lm_400(txt, i_statementLst, i_varDecls, i_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, i_varDecls);

    case ( txt,
           _,
           _,
           i_varDecls )
      then (txt, i_varDecls);
  end matchcontinue;
end elseExpr;

protected function fun_402
  input Tpl.Text in_txt;
  input Boolean in_it;
  input DAE.ComponentRef in_i_cref_componentRef;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input DAE.Exp in_i_cref;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_it, in_i_cref_componentRef, in_i_varDecls, in_i_preExp, in_i_context, in_i_cref)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cref_componentRef;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      DAE.Exp i_cref;

    case ( txt,
           false,
           _,
           i_varDecls,
           i_preExp,
           i_context,
           i_cref )
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs(txt, i_cref, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_cref_componentRef,
           i_varDecls,
           i_preExp,
           i_context,
           _ )
      equation
        txt = contextCref(txt, i_cref_componentRef, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_402;

public function scalarLhsCref
  input Tpl.Text in_txt;
  input DAE.Exp in_i_cref;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_cref, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_cref as DAE.CREF(componentRef = (i_cref_componentRef as DAE.CREF_IDENT(subscriptLst = i_subs)))),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Subscript> i_subs;
        DAE.ComponentRef i_cref_componentRef;
        DAE.Exp i_cref;
        Boolean ret_0;
      equation
        ret_0 = SimCode.crefNoSub(i_cref_componentRef);
        (txt, i_varDecls, i_preExp) = fun_402(txt, ret_0, i_cref_componentRef, i_varDecls, i_preExp, i_context, i_cref);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_cref as DAE.CREF(componentRef = (i_cref_componentRef as DAE.CREF_QUAL(subscriptLst = i_subs)))),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Subscript> i_subs;
        DAE.ComponentRef i_cref_componentRef;
        DAE.Exp i_cref;
      equation
        txt = contextCref(txt, i_cref_componentRef, i_context);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ONLY IDENT SUPPORTED"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end scalarLhsCref;

public function rhsCref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cref;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cref, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident),
           i_ty )
      local
        DAE.Ident i_ident;
      equation
        txt = rhsCrefType(txt, i_ty);
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef),
           i_ty )
      local
        DAE.ComponentRef i_componentRef;
        DAE.Ident i_ident;
      equation
        txt = rhsCrefType(txt, i_ty);
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = rhsCref(txt, i_componentRef, i_ty);
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
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end rhsCrefType;

protected function fun_406
  input Tpl.Text in_txt;
  input Boolean in_i_bool;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_bool)
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
end fun_406;

public function daeExp
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_e as DAE.ICONST(integer = i_integer)),
           _,
           i_preExp,
           i_varDecls )
      local
        Integer i_integer;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.RCONST(real = i_real)),
           _,
           i_preExp,
           i_varDecls )
      local
        Real i_real;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, realString(i_real));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.SCONST(string = i_string)),
           _,
           i_preExp,
           i_varDecls )
      local
        String i_string;
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpSconst(txt, i_string, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.BCONST(bool = i_bool)),
           _,
           i_preExp,
           i_varDecls )
      local
        Boolean i_bool;
        DAE.Exp i_e;
      equation
        txt = fun_406(txt, i_bool);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CREF(componentRef = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.BINARY(exp1 = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpBinary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.UNARY(operator = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpUnary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.LBINARY(exp1 = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpLbinary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.LUNARY(operator = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpLunary(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.RELATION(exp1 = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpRelation(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.IFEXP(expCond = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpIf(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CALL(path = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCall(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.ARRAY(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpArray(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.MATRIX(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMatrix(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CAST(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCast(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.ASUB(exp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpAsub(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.SIZE(exp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpSize(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.REDUCTION(path = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpReduction(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.VALUEBLOCK(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpValueblock(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.LIST(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpList(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.CONS(ty = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCons(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.META_TUPLE(listExp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaTuple(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.META_OPTION(exp = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaOption(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_e as DAE.METARECORDCALL(path = _)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetarecordcall(txt, i_e, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_EXP"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExp;

public function daeExpSconst
  input Tpl.Text txt;
  input String i_string;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  String ret_2;
  Tpl.Text i_escapedStr;
  Tpl.Text i_strVar;
algorithm
  (i_strVar, out_i_varDecls) := tempDecl(emptyTxt, "modelica_string", i_varDecls);
  ret_2 := Util.escapeModelicaStringToCString(i_string);
  i_escapedStr := Tpl.writeStr(emptyTxt, ret_2);
  out_i_preExp := Tpl.writeTok(i_preExp, Tpl.ST_STRING("init_modelica_string(&"));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_strVar);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(",\""));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_escapedStr);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING("\");"));
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_strVar);
end daeExpSconst;

protected function fun_409
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input DAE.Exp in_i_exp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_context, in_i_cr, in_i_varDecls, in_i_preExp, in_i_exp)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      DAE.Exp i_exp;

    case ( txt,
           (i_context as SimCode.FUNCTION_CONTEXT()),
           _,
           i_varDecls,
           i_preExp,
           i_exp )
      local
        SimCode.Context i_context;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs2(txt, i_exp, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_context,
           i_cr,
           i_varDecls,
           i_preExp,
           _ )
      local
        SimCode.Context i_context;
      equation
        (txt, i_preExp, i_varDecls) = daeExpRecordCrefRhs(txt, i_cr, i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_409;

public function daeExpCrefRhs
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_exp as DAE.CREF(componentRef = (i_cr as DAE.CREF_IDENT(subscriptLst = {})), ty = DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)))),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_cr;
        DAE.Exp i_exp;
      equation
        (txt, i_varDecls, i_preExp) = fun_409(txt, i_context, i_cr, i_varDecls, i_preExp, i_exp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_FUNCTION_REFERENCE_FUNC()),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_cr;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_fnptr)boxptr_"));
        txt = functionName(txt, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_exp,
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExpCrefRhs2(txt, i_exp, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCrefRhs;

protected function lm_411
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.INDEX(exp = i_exp) :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_411(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_411(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_411;

protected function fun_412
  input Tpl.Text in_txt;
  input Boolean in_it;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_ty;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_preExp, in_i_varDecls, in_i_ty, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;
      DAE.ExpType i_ty;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;

    case ( txt,
           false,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        list<DAE.Subscript> ret_4;
        Tpl.Text i_spec1;
        Tpl.Text i_tmp;
        Tpl.Text i_arrayType;
        Tpl.Text i_arrName;
      equation
        i_arrName = contextArrayCref(emptyTxt, i_cr, i_context);
        i_arrayType = expTypeArray(emptyTxt, i_ty);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayType), i_varDecls);
        ret_4 = SimCode.crefSubs(i_cr);
        (i_spec1, i_preExp, i_varDecls) = daeExpCrefRhsIndexSpec(emptyTxt, ret_4, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("index_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayType);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_arrName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_spec1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        list<DAE.Subscript> ret_7;
        Tpl.Text i_dimsValuesStr;
        Integer ret_5;
        list<DAE.Subscript> ret_4;
        Tpl.Text i_dimsLenStr;
        Tpl.Text i_arrayType;
        DAE.ComponentRef ret_1;
        Tpl.Text i_arrName;
      equation
        ret_1 = Exp.crefStripLastSubs(i_cr);
        i_arrName = contextCref(emptyTxt, ret_1, i_context);
        i_arrayType = expTypeArray(emptyTxt, i_ty);
        ret_4 = SimCode.crefSubs(i_cr);
        ret_5 = listLength(ret_4);
        i_dimsLenStr = Tpl.writeStr(emptyTxt, intString(ret_5));
        ret_7 = SimCode.crefSubs(i_cr);
        i_dimsValuesStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_dimsValuesStr, i_varDecls, i_preExp) = lm_411(i_dimsValuesStr, ret_7, i_varDecls, i_preExp, i_context);
        i_dimsValuesStr = Tpl.popIter(i_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*"));
        txt = Tpl.writeText(txt, i_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_element_addr(&"));
        txt = Tpl.writeText(txt, i_arrName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dimsLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_412;

protected function fun_413
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_413;

protected function fun_414
  input Tpl.Text in_txt;
  input Boolean in_it;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_ty;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_preExp, in_i_varDecls, in_i_ty, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;
      DAE.ExpType i_ty;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;

    case ( txt,
           false,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        Boolean ret_0;
      equation
        ret_0 = SimCode.crefSubIsScalar(i_cr);
        (txt, i_preExp, i_varDecls) = fun_412(txt, ret_0, i_preExp, i_varDecls, i_ty, i_context, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        Tpl.Text i_cast;
      equation
        i_cast = fun_413(emptyTxt, i_ty);
        txt = Tpl.writeText(txt, i_cast);
        txt = contextCref(txt, i_cr, i_context);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_414;

protected function fun_415
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_box;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_ty;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_it, in_i_box, in_i_preExp, in_i_varDecls, in_i_ty, in_i_context, in_i_cr)
    local
      Tpl.Text txt;
      Tpl.Text i_box;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;
      DAE.ExpType i_ty;
      SimCode.Context i_context;
      DAE.ComponentRef i_cr;

    case ( txt,
           "",
           _,
           i_preExp,
           i_varDecls,
           i_ty,
           i_context,
           i_cr )
      local
        Boolean ret_0;
      equation
        ret_0 = SimCode.crefIsScalar(i_cr, i_context);
        (txt, i_preExp, i_varDecls) = fun_414(txt, ret_0, i_preExp, i_varDecls, i_ty, i_context, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_box,
           i_preExp,
           i_varDecls,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeText(txt, i_box);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_415;

public function daeExpCrefRhs2
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_ENUMERATION(index = _)),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_cr;
        Integer ret_0;
      equation
        ret_0 = Exp.getEnumIndexfromCref(i_cr);
        txt = Tpl.writeStr(txt, intString(ret_0));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_cref as DAE.CREF(componentRef = i_cr, ty = i_ty)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        DAE.ComponentRef i_cr;
        DAE.Exp i_cref;
        String str_1;
        Tpl.Text i_box;
      equation
        (i_box, i_preExp, i_varDecls) = daeExpCrefRhsArrayBox(emptyTxt, i_cref, i_context, i_preExp, i_varDecls);
        str_1 = Tpl.textString(i_box);
        (txt, i_preExp, i_varDecls) = fun_415(txt, str_1, i_box, i_preExp, i_varDecls, i_ty, i_context, i_cr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCrefRhs2;

protected function fun_417
  input Tpl.Text in_txt;
  input DAE.Subscript in_i_sub;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_sub, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           i_varDecls,
           i_preExp,
           i_context )
      local
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1), make_index_array(1, "));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), \'S\'"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           i_varDecls,
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1), (0), \'W\'"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           i_varDecls,
           i_preExp,
           i_context )
      local
        DAE.Exp i_exp;
        Tpl.Text i_tmp;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_integer", i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = size_of_dimension_integer_array("));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", 1);"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", integer_array_make_index_array(&"));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), \'A\'"));
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_417;

protected function lm_418
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_sub :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
        DAE.Subscript i_sub;
      equation
        (txt, i_varDecls, i_preExp) = fun_417(txt, i_sub, i_varDecls, i_preExp, i_context);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_418(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Subscript> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_418(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_418;

public function daeExpCrefRhsIndexSpec
  input Tpl.Text txt;
  input list<DAE.Subscript> i_subs;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_tmp;
  Tpl.Text i_idx__str;
  Integer ret_1;
  Tpl.Text i_nridx__str;
algorithm
  ret_1 := listLength(i_subs);
  i_nridx__str := Tpl.writeStr(emptyTxt, intString(ret_1));
  i_idx__str := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_idx__str, out_i_varDecls, out_i_preExp) := lm_418(i_idx__str, i_subs, i_varDecls, i_preExp, i_context);
  i_idx__str := Tpl.popIter(i_idx__str);
  (i_tmp, out_i_varDecls) := tempDecl(emptyTxt, "index_spec_t", out_i_varDecls);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING("create_index_spec(&"));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_tmp);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(", "));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_nridx__str);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(", "));
  out_i_preExp := Tpl.writeText(out_i_preExp, i_idx__str);
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_STRING(");"));
  out_i_preExp := Tpl.writeTok(out_i_preExp, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_tmp);
end daeExpCrefRhsIndexSpec;

protected function lm_420
  input Tpl.Text in_txt;
  input list<Option<Integer>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_dim as SOME(i_i)) :: rest )
      local
        list<Option<Integer>> rest;
        Integer i_i;
        Option<Integer> i_dim;
      equation
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.nextIter(txt);
        txt = lm_420(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<Option<Integer>> rest;
      equation
        txt = lm_420(txt, rest);
      then txt;
  end matchcontinue;
end lm_420;

protected function fun_421
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.ComponentRef in_i_cref_componentRef;
  input Tpl.Text in_i_preExp;
  input list<Option<Integer>> in_i_dims;
  input Tpl.Text in_i_varDecls;
  input DAE.ExpType in_i_aty;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_context, in_i_cref_componentRef, in_i_preExp, in_i_dims, in_i_varDecls, in_i_aty)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cref_componentRef;
      Tpl.Text i_preExp;
      list<Option<Integer>> i_dims;
      Tpl.Text i_varDecls;
      DAE.ExpType i_aty;

    case ( txt,
           SimCode.SIMULATION(genDiscrete = _),
           i_cref_componentRef,
           i_preExp,
           i_dims,
           i_varDecls,
           i_aty )
      local
        Tpl.Text i_dimsValuesStr;
        Integer ret_3;
        Tpl.Text i_dimsLenStr;
        Tpl.Text txt_1;
        Tpl.Text i_tmpArr;
      equation
        txt_1 = expTypeArray(emptyTxt, i_aty);
        (i_tmpArr, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_1), i_varDecls);
        ret_3 = listLength(i_dims);
        i_dimsLenStr = Tpl.writeStr(emptyTxt, intString(ret_3));
        i_dimsValuesStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_dimsValuesStr = lm_420(i_dimsValuesStr, i_dims);
        i_dimsValuesStr = Tpl.popIter(i_dimsValuesStr);
        i_preExp = expTypeShort(i_preExp, i_aty);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_array_create(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmpArr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = arrayCrefCStr(i_preExp, i_cref_componentRef);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dimsLenStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dimsValuesStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpArr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           _,
           i_varDecls,
           _ )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_421;

public function daeExpCrefRhsArrayBox
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_cref as DAE.CREF(ty = DAE.ET_ARRAY(ty = i_aty, arrayDimensions = i_dims), componentRef = i_cref_componentRef)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_cref_componentRef;
        list<Option<Integer>> i_dims;
        DAE.ExpType i_aty;
        DAE.Exp i_cref;
      equation
        (txt, i_preExp, i_varDecls) = fun_421(txt, i_context, i_cref_componentRef, i_preExp, i_dims, i_varDecls, i_aty);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCrefRhsArrayBox;

protected function lm_423
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_record__name;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_record__name;
algorithm
  (out_txt, out_i_record__name) :=
  matchcontinue(in_txt, in_items, in_i_record__name)
    local
      Tpl.Text txt;
      Tpl.Text i_record__name;

    case ( txt,
           {},
           i_record__name )
      then (txt, i_record__name);

    case ( txt,
           i_v :: rest,
           i_record__name )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpVar i_v;
      equation
        (txt, i_record__name) = daeExpRecordMemberCref(txt, i_v, i_record__name);
        txt = Tpl.nextIter(txt);
        (txt, i_record__name) = lm_423(txt, rest, i_record__name);
      then (txt, i_record__name);

    case ( txt,
           _ :: rest,
           i_record__name )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_record__name) = lm_423(txt, rest, i_record__name);
      then (txt, i_record__name);
  end matchcontinue;
end lm_423;

protected function fun_424
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_cr, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_cr as DAE.CREF_IDENT(identType = DAE.ET_COMPLEX(name = i_record__path, varLst = i_var__lst))),
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_var__lst;
        Absyn.Path i_record__path;
        DAE.ComponentRef i_cr;
        Tpl.Text i_vars;
        Tpl.Text i_ret__var;
        Tpl.Text i_ret__type;
        Tpl.Text i_record__type__name;
        Tpl.Text i_record__name;
      equation
        i_record__name = cref(emptyTxt, i_cr);
        i_record__type__name = underscorePath(emptyTxt, i_record__path);
        i_ret__type = Tpl.writeText(emptyTxt, i_record__type__name);
        i_ret__type = Tpl.writeTok(i_ret__type, Tpl.ST_STRING("_rettype"));
        (i_ret__var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_ret__type), i_varDecls);
        i_vars = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_vars, i_record__name) = lm_423(i_vars, i_var__lst, i_record__name);
        i_vars = Tpl.popIter(i_vars);
        i_preExp = Tpl.writeText(i_preExp, i_ret__var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = _"));
        i_preExp = Tpl.writeText(i_preExp, i_record__type__name);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_vars);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_ret__var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_ret__type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_424;

public function daeExpRecordCrefRhs
  input Tpl.Text txt;
  input DAE.ComponentRef i_cr;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) := fun_424(txt, i_cr, i_preExp, i_varDecls);
end daeExpRecordCrefRhs;

protected function fun_426
  input Tpl.Text in_txt;
  input DAE.ExpVar in_i_var;
  input Tpl.Text in_i_recordName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var, in_i_recordName)
    local
      Tpl.Text txt;
      Tpl.Text i_recordName;

    case ( txt,
           DAE.COMPLEX_VAR(name = i_var__name),
           i_recordName )
      local
        String i_var__name;
      equation
        txt = Tpl.writeText(txt, i_recordName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = Tpl.writeStr(txt, i_var__name);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_426;

public function daeExpRecordMemberCref
  input Tpl.Text txt;
  input DAE.ExpVar i_var;
  input Tpl.Text i_recordName;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_recordName;
algorithm
  out_txt := fun_426(txt, i_var, i_recordName);
  out_i_recordName := i_recordName;
end daeExpRecordMemberCref;

protected function fun_428
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_428;

protected function fun_429
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_429;

protected function fun_430
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_430;

protected function fun_431
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_431;

protected function fun_432
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_scalar"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_scalar"));
      then txt;
  end matchcontinue;
end fun_432;

protected function fun_433
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;
  end matchcontinue;
end fun_433;

protected function fun_434
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_434;

protected function fun_435
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input SimCode.Context in_i_context;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_operator, in_i_context, in_i_exp, in_i_e2, in_i_e1, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      DAE.Exp i_exp;
      Tpl.Text i_e2;
      Tpl.Text i_e1;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ADD(ty = DAE.ET_STRING()),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        Tpl.Text i_tmpStr;
      equation
        (i_tmpStr, i_varDecls) = tempDecl(emptyTxt, "modelica_string", i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cat_modelica_string(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmpStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(",&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(",&"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmpStr);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" + "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" - "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" * "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" / "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW(ty = _),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("pow((modelica_real)"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", (modelica_real)"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.UMINUS(ty = _),
           i_context,
           i_exp,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        (txt, i_preExp, i_varDecls) = daeExpUnary(txt, i_exp, i_context, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD_ARR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_428(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("add_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB_ARR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_429(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("sub_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_ARR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for MUL_ARR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV_ARR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for DIV_ARR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_SCALAR_ARRAY(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_430(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("mul_alloc_scalar_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_ARRAY_SCALAR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_431(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("mul_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_scalar(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for ADD_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ADD_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for ADD_ARRAY_SCALAR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for SUB_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.SUB_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for SUB_ARRAY_SCALAR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_SCALAR_PRODUCT(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_type;
      equation
        i_type = fun_432(emptyTxt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mul_"));
        txt = Tpl.writeText(txt, i_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_product(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MUL_MATRIX_PRODUCT(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
        Tpl.Text i_typeShort;
      equation
        i_typeShort = fun_433(emptyTxt, i_ty);
        i_type = Tpl.writeText(emptyTxt, i_typeShort);
        i_type = Tpl.writeTok(i_type, Tpl.ST_STRING("_array"));
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("mul_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_typeShort);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_matrix_product_smart(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV_ARRAY_SCALAR(ty = i_ty),
           _,
           _,
           i_e2,
           i_e1,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_434(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("div_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_scalar(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.DIV_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for DIV_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARRAY_SCALAR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_SCALAR_ARRAY"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_ARR(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARR"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.POW_ARR2(ty = _),
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARR2"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_435;

public function daeExpBinary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_exp as DAE.BINARY(exp1 = i_exp1, exp2 = i_exp2, operator = i_operator)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp2;
        DAE.Exp i_exp1;
        DAE.Exp i_exp;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp2, i_context, i_preExp, i_varDecls);
        (txt, i_preExp, i_varDecls) = fun_435(txt, i_operator, i_context, i_exp, i_e2, i_e1, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpBinary;

protected function fun_437
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_e;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_operator, in_i_preExp, in_i_e)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      Tpl.Text i_e;

    case ( txt,
           DAE.UMINUS(ty = _),
           i_preExp,
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(-"));
        txt = Tpl.writeText(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp);

    case ( txt,
           DAE.UPLUS(ty = _),
           i_preExp,
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp);

    case ( txt,
           DAE.UMINUS_ARR(ty = DAE.ET_ARRAY(ty = DAE.ET_REAL())),
           i_preExp,
           i_e )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("usub_real_array(&"));
        i_preExp = Tpl.writeText(i_preExp, i_e);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_e);
      then (txt, i_preExp);

    case ( txt,
           DAE.UMINUS_ARR(ty = _),
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("unary minus for non-real arrays not implemented"));
      then (txt, i_preExp);

    case ( txt,
           DAE.UPLUS_ARR(ty = _),
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UPLUS_ARR_NOT_IMPLEMENTED"));
      then (txt, i_preExp);

    case ( txt,
           _,
           i_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpUnary:ERR"));
      then (txt, i_preExp);
  end matchcontinue;
end fun_437;

public function daeExpUnary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.UNARY(exp = i_exp, operator = i_operator),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp;
        Tpl.Text i_e;
      equation
        (i_e, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (txt, i_preExp) = fun_437(txt, i_operator, i_preExp, i_e);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpUnary;

protected function fun_439
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_operator, in_i_e2, in_i_e1)
    local
      Tpl.Text txt;
      Tpl.Text i_e2;
      Tpl.Text i_e1;

    case ( txt,
           DAE.AND(),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.OR(),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || "));
        txt = Tpl.writeText(txt, i_e2);
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
end fun_439;

public function daeExpLbinary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.LBINARY(exp1 = i_exp1, exp2 = i_exp2, operator = i_operator),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp2;
        DAE.Exp i_exp1;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp2, i_context, i_preExp, i_varDecls);
        txt = fun_439(txt, i_operator, i_e2, i_e1);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpLbinary;

protected function fun_441
  input Tpl.Text in_txt;
  input DAE.Operator in_i_operator;
  input Tpl.Text in_i_e;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_operator, in_i_e)
    local
      Tpl.Text txt;
      Tpl.Text i_e;

    case ( txt,
           DAE.NOT(),
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_441;

public function daeExpLunary
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.LUNARY(exp = i_exp, operator = i_operator),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_operator;
        DAE.Exp i_exp;
        Tpl.Text i_e;
      equation
        (i_e, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        txt = fun_441(txt, i_operator, i_e);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpLunary;

protected function fun_443
  input Tpl.Text in_txt;
  input DAE.Operator in_i_rel_operator;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_rel_operator, in_i_e2, in_i_e1)
    local
      Tpl.Text txt;
      Tpl.Text i_e2;
      Tpl.Text i_e1;

    case ( txt,
           DAE.LESS(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" < "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" < "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" > "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" > "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" <= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" <= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_STRING()),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("# string comparison not supported\n"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" >= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" >= "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") || ("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_STRING()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!strcmp("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_BOOL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((!"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") || ("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_STRING()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(strcmp("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_INT()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, i_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_REAL()),
           i_e2,
           i_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, i_e2);
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
end fun_443;

protected function fun_444
  input Tpl.Text in_txt;
  input String in_it;
  input Tpl.Text in_i_simRel;
  input DAE.Operator in_i_rel_operator;
  input DAE.Exp in_i_rel_exp2;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input DAE.Exp in_i_rel_exp1;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_it, in_i_simRel, in_i_rel_operator, in_i_rel_exp2, in_i_varDecls, in_i_preExp, in_i_context, in_i_rel_exp1)
    local
      Tpl.Text txt;
      Tpl.Text i_simRel;
      DAE.Operator i_rel_operator;
      DAE.Exp i_rel_exp2;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      DAE.Exp i_rel_exp1;

    case ( txt,
           "",
           _,
           i_rel_operator,
           i_rel_exp2,
           i_varDecls,
           i_preExp,
           i_context,
           i_rel_exp1 )
      local
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp2, i_context, i_preExp, i_varDecls);
        txt = fun_443(txt, i_rel_operator, i_e2, i_e1);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_simRel,
           _,
           _,
           i_varDecls,
           i_preExp,
           _,
           _ )
      equation
        txt = Tpl.writeText(txt, i_simRel);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_444;

public function daeExpRelation
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_rel as DAE.RELATION(exp1 = i_rel_exp1, exp2 = i_rel_exp2, operator = i_rel_operator)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_rel_operator;
        DAE.Exp i_rel_exp2;
        DAE.Exp i_rel_exp1;
        DAE.Exp i_rel;
        String str_1;
        Tpl.Text i_simRel;
      equation
        (i_simRel, i_preExp, i_varDecls) = daeExpRelationSim(emptyTxt, i_rel, i_context, i_preExp, i_varDecls);
        str_1 = Tpl.textString(i_simRel);
        (txt, i_varDecls, i_preExp) = fun_444(txt, str_1, i_simRel, i_rel_operator, i_rel_exp2, i_varDecls, i_preExp, i_context, i_rel_exp1);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpRelation;

protected function fun_446
  input Tpl.Text in_txt;
  input DAE.Operator in_i_rel_operator;
  input Tpl.Text in_i_e2;
  input Tpl.Text in_i_e1;
  input Tpl.Text in_i_res;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_rel_operator, in_i_e2, in_i_e1, in_i_res, in_i_preExp)
    local
      Tpl.Text txt;
      Tpl.Text i_e2;
      Tpl.Text i_e1;
      Tpl.Text i_res;
      Tpl.Text i_preExp;

    case ( txt,
           DAE.LESS(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONLESS("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           DAE.LESSEQ(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONLESSEQ("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           DAE.GREATER(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONGREATER("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           DAE.GREATEREQ(ty = _),
           i_e2,
           i_e1,
           i_res,
           i_preExp )
      equation
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("RELATIONGREATEREQ("));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_e2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           _,
           _,
           _,
           _,
           i_preExp )
      then (txt, i_preExp);
  end matchcontinue;
end fun_446;

protected function fun_447
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input DAE.Operator in_i_rel_operator;
  input DAE.Exp in_i_rel_exp2;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input DAE.Exp in_i_rel_exp1;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_context, in_i_rel_operator, in_i_rel_exp2, in_i_varDecls, in_i_preExp, in_i_rel_exp1)
    local
      Tpl.Text txt;
      DAE.Operator i_rel_operator;
      DAE.Exp i_rel_exp2;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      DAE.Exp i_rel_exp1;

    case ( txt,
           (i_context as SimCode.SIMULATION(genDiscrete = _)),
           i_rel_operator,
           i_rel_exp2,
           i_varDecls,
           i_preExp,
           i_rel_exp1 )
      local
        SimCode.Context i_context;
        Tpl.Text i_res;
        Tpl.Text i_e2;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp1, i_context, i_preExp, i_varDecls);
        (i_e2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_rel_exp2, i_context, i_preExp, i_varDecls);
        (i_res, i_varDecls) = tempDecl(emptyTxt, "modelica_boolean", i_varDecls);
        (txt, i_preExp) = fun_446(txt, i_rel_operator, i_e2, i_e1, i_res, i_preExp);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           _,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_447;

public function daeExpRelationSim
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_rel as DAE.RELATION(exp1 = i_rel_exp1, exp2 = i_rel_exp2, operator = i_rel_operator)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Operator i_rel_operator;
        DAE.Exp i_rel_exp2;
        DAE.Exp i_rel_exp1;
        DAE.Exp i_rel;
      equation
        (txt, i_varDecls, i_preExp) = fun_447(txt, i_context, i_rel_operator, i_rel_exp2, i_varDecls, i_preExp, i_rel_exp1);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpRelationSim;

public function daeExpIf
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.IFEXP(expCond = i_expCond, expThen = i_expThen, expElse = i_expElse),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_expElse;
        DAE.Exp i_expThen;
        DAE.Exp i_expCond;
        Tpl.Text i_eElse;
        Tpl.Text i_preExpElse;
        Tpl.Text i_eThen;
        Tpl.Text i_preExpThen;
        Tpl.Text i_resVar;
        Tpl.Text i_resVarType;
        Tpl.Text i_condVar;
        Tpl.Text i_condExp;
      equation
        (i_condExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_expCond, i_context, i_preExp, i_varDecls);
        (i_condVar, i_varDecls) = tempDecl(emptyTxt, "modelica_boolean", i_varDecls);
        i_resVarType = expTypeFromExpArrayIf(emptyTxt, i_expThen);
        (i_resVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_resVarType), i_varDecls);
        i_preExpThen = emptyTxt;
        (i_eThen, i_preExpThen, i_varDecls) = daeExp(emptyTxt, i_expThen, i_context, i_preExpThen, i_varDecls);
        i_preExpElse = emptyTxt;
        (i_eElse, i_preExpElse, i_varDecls) = daeExp(emptyTxt, i_expElse, i_context, i_preExpElse, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_condVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_condExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING_LIST({
                                              ";\n",
                                              "if ("
                                          }, false));
        i_preExp = Tpl.writeText(i_preExp, i_condVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(") {\n"));
        i_preExp = Tpl.pushBlock(i_preExp, Tpl.BT_INDENT(2));
        i_preExp = Tpl.writeText(i_preExp, i_preExpThen);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_resVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_eThen);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        i_preExp = Tpl.popBlock(i_preExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE("} else {\n"));
        i_preExp = Tpl.pushBlock(i_preExp, Tpl.BT_INDENT(2));
        i_preExp = Tpl.writeText(i_preExp, i_preExpElse);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_resVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_eElse);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        i_preExp = Tpl.popBlock(i_preExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("}"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_resVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpIf;

protected function fun_450
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_450;

protected function fun_451
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_arg_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_arg_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_451;

protected function lm_452
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_452(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_452(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_452;

protected function lm_453
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_453(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_453(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_453;

protected function fun_454
  input Tpl.Text in_txt;
  input Boolean in_i_builtin;
  input Tpl.Text in_i_retType;
  input Tpl.Text in_i_retVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_builtin, in_i_retType, in_i_retVar)
    local
      Tpl.Text txt;
      Tpl.Text i_retType;
      Tpl.Text i_retVar;

    case ( txt,
           false,
           i_retType,
           i_retVar )
      equation
        txt = Tpl.writeText(txt, i_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, i_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1"));
      then txt;

    case ( txt,
           _,
           _,
           i_retVar )
      equation
        txt = Tpl.writeText(txt, i_retVar);
      then txt;
  end matchcontinue;
end fun_454;

protected function lm_455
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_455(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_455(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_455;

public function daeExpCall
  input Tpl.Text in_txt;
  input DAE.Exp in_i_call;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_call, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "DIVISION"), expLst = {i_e1, i_e2, DAE.SCONST(string = i_string)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        String i_string;
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        String ret_3;
        Tpl.Text i_var3;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        ret_3 = Util.escapeModelicaStringToCString(i_string);
        i_var3 = Tpl.writeStr(emptyTxt, ret_3);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DIVISION("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",\""));
        txt = Tpl.writeText(txt, i_var3);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, ty = i_ty, path = Absyn.IDENT(name = "DIVISION_ARRAY_SCALAR"), expLst = {i_e1, i_e2, DAE.SCONST(string = i_string)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        String i_string;
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        DAE.ExpType i_ty;
        String ret_5;
        Tpl.Text i_var3;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
        Tpl.Text i_var;
        Tpl.Text i_type;
      equation
        i_type = fun_450(emptyTxt, i_ty);
        (i_var, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_type), i_varDecls);
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        ret_5 = Util.escapeModelicaStringToCString(i_string);
        i_var3 = Tpl.writeStr(emptyTxt, ret_5);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("division_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_type);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_scalar(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_var);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(",\""));
        i_preExp = Tpl.writeText(i_preExp, i_var3);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("\");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_var);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "der"), expLst = {(i_arg as DAE.CREF(componentRef = i_arg_componentRef))}),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_arg_componentRef;
        DAE.Exp i_arg;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$DER"));
        txt = cref(txt, i_arg_componentRef);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "pre"), expLst = {(i_arg as DAE.CREF(ty = i_arg_ty, componentRef = i_arg_componentRef))}),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ComponentRef i_arg_componentRef;
        DAE.ExpType i_arg_ty;
        DAE.Exp i_arg;
        Tpl.Text i_cast;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
      equation
        i_retType = expTypeArrayIf(emptyTxt, i_arg_ty);
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_cast = fun_451(emptyTxt, i_arg_ty);
        i_preExp = Tpl.writeText(i_preExp, i_retVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_cast);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("pre("));
        i_preExp = cref(i_preExp, i_arg_componentRef);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_retVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "max"), expLst = {i_e1, i_e2}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("max("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "min"), expLst = {i_e1, i_e2}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e2;
        DAE.Exp i_e1;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e2, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("min("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "abs"), expLst = {i_e1}, ty = DAE.ET_INT()),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e1;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::abs("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "abs"), expLst = {i_e1}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e1;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e1, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fabs("));
        txt = Tpl.writeText(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "max"), expLst = {i_array}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_array;
        Tpl.Text txt_3;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_expVar;
      equation
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_array, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_array);
        txt_3 = expTypeFromExpModelica(emptyTxt, i_array);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_3), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = max_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_expVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "min"), expLst = {i_array}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_array;
        Tpl.Text txt_3;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_expVar;
      equation
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_array, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_array);
        txt_3 = expTypeFromExpModelica(emptyTxt, i_array);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(txt_3), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = min_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_expVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "promote"), expLst = {i_A, i_n}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_n;
        DAE.Exp i_A;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_A, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_n, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_A);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arr__tp__str), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("promote_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "transpose"), expLst = {i_A}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_A;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_A, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_A);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arr__tp__str), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("transpose_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "identity"), expLst = {i_A}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_A;
        Tpl.Text i_tvar;
        Tpl.Text i_arr__tp__str;
        Tpl.Text i_var1;
      equation
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_A, i_context, i_preExp, i_varDecls);
        i_arr__tp__str = expTypeFromExpArray(emptyTxt, i_A);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arr__tp__str), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("identity_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arr__tp__str);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "String"), expLst = {i_s, i_minlen, i_leftjust, i_signdig}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_signdig;
        DAE.Exp i_leftjust;
        DAE.Exp i_minlen;
        DAE.Exp i_s;
        Tpl.Text i_typeStr;
        Tpl.Text i_signdigExp;
        Tpl.Text i_leftjustExp;
        Tpl.Text i_minlenExp;
        Tpl.Text i_sExp;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_string", i_varDecls);
        (i_sExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s, i_context, i_preExp, i_varDecls);
        (i_minlenExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_minlen, i_context, i_preExp, i_varDecls);
        (i_leftjustExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_leftjust, i_context, i_preExp, i_varDecls);
        (i_signdigExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_signdig, i_context, i_preExp, i_varDecls);
        i_typeStr = expTypeFromExpModelica(emptyTxt, i_s);
        i_preExp = Tpl.writeText(i_preExp, i_typeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_to_modelica_string(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_sExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_minlenExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_leftjustExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_signdigExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "delay"), expLst = {DAE.ICONST(integer = i_index), i_e, i_d, i_delayMax}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_delayMax;
        DAE.Exp i_d;
        DAE.Exp i_e;
        Integer i_index;
        Tpl.Text i_var3;
        Tpl.Text i_var2;
        Tpl.Text i_var1;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_real", i_varDecls);
        (i_var1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_var2, i_preExp, i_varDecls) = daeExp(emptyTxt, i_d, i_context, i_preExp, i_varDecls);
        (i_var3, i_preExp, i_varDecls) = daeExp(emptyTxt, i_delayMax, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = delayImpl("));
        i_preExp = Tpl.writeStr(i_preExp, intString(i_index));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var1);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", time, "));
        i_preExp = Tpl.writeText(i_preExp, i_var2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_var3);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "mmc_get_field"), expLst = {i_s1, DAE.ICONST(integer = i_i)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_i;
        DAE.Exp i_s1;
        Tpl.Text i_expPart;
        Tpl.Text i_tvar;
      equation
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s1, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("), "));
        i_preExp = Tpl.writeStr(i_preExp, intString(i_i));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("));"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "mmc_unbox_record"), expLst = {i_s1}, ty = i_ty),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        DAE.Exp i_s1;
        Tpl.Text i_argStr;
      equation
        (i_argStr, i_preExp, i_varDecls) = daeExp(emptyTxt, i_s1, i_context, i_preExp, i_varDecls);
        (txt, i_preExp, i_varDecls) = unboxRecord(txt, Tpl.textString(i_argStr), i_ty, i_preExp, i_varDecls);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, ty = DAE.ET_NORETCALL(), expLst = i_expLst, path = i_path, builtin = i_builtin),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Boolean i_builtin;
        Absyn.Path i_path;
        list<DAE.Exp> i_expLst;
        Tpl.Text i_funName;
        Tpl.Text i_argStr;
      equation
        i_argStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argStr, i_varDecls, i_preExp) = lm_452(i_argStr, i_expLst, i_varDecls, i_preExp, i_context);
        i_argStr = Tpl.popIter(i_argStr);
        i_funName = underscorePath(emptyTxt, i_path);
        i_preExp = daeExpCallBuiltinPrefix(i_preExp, i_builtin);
        i_preExp = Tpl.writeText(i_preExp, i_funName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_argStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* NORETCALL */"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, expLst = i_expLst, path = i_path, builtin = i_builtin),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Boolean i_builtin;
        Absyn.Path i_path;
        list<DAE.Exp> i_expLst;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_funName;
        Tpl.Text i_argStr;
      equation
        i_argStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argStr, i_varDecls, i_preExp) = lm_453(i_argStr, i_expLst, i_varDecls, i_preExp, i_context);
        i_argStr = Tpl.popIter(i_argStr);
        i_funName = underscorePath(emptyTxt, i_path);
        i_retType = Tpl.writeText(emptyTxt, i_funName);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_retVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = daeExpCallBuiltinPrefix(i_preExp, i_builtin);
        i_preExp = Tpl.writeText(i_preExp, i_funName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_argStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = fun_454(txt, i_builtin, i_retType, i_retVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = true, expLst = i_expLst, path = i_path, builtin = i_builtin),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Boolean i_builtin;
        Absyn.Path i_path;
        list<DAE.Exp> i_expLst;
        Tpl.Text i_retVar;
        Tpl.Text i_retType;
        Tpl.Text i_funName;
        Tpl.Text i_argStr;
      equation
        i_argStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_argStr, i_varDecls, i_preExp) = lm_455(i_argStr, i_expLst, i_varDecls, i_preExp, i_context);
        i_argStr = Tpl.popIter(i_argStr);
        i_funName = underscorePath(emptyTxt, i_path);
        i_retType = Tpl.writeText(emptyTxt, i_funName);
        i_retType = Tpl.writeTok(i_retType, Tpl.ST_STRING("_rettype"));
        (i_retVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_retType), i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_retVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = daeExpCallBuiltinPrefix(i_preExp, i_builtin);
        i_preExp = Tpl.writeText(i_preExp, i_funName);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_argStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_retVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCall;

public function daeExpCallBuiltinPrefix
  input Tpl.Text in_txt;
  input Boolean in_i_builtin;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_builtin)
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

protected function fun_458
  input Tpl.Text in_txt;
  input Boolean in_i_scalar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_scalar)
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
end fun_458;

protected function fun_459
  input Tpl.Text in_txt;
  input Boolean in_i_scalar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_scalar)
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
end fun_459;

protected function fun_460
  input Tpl.Text in_txt;
  input Boolean in_i_scalar;
  input DAE.Exp in_i_e;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_scalar, in_i_e)
    local
      Tpl.Text txt;
      DAE.Exp i_e;

    case ( txt,
           false,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;

    case ( txt,
           _,
           i_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = expTypeFromExpModelica(txt, i_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_460;

protected function lm_461
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;
  input Boolean in_i_scalar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context, in_i_scalar)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;
      Boolean i_scalar;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_e :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_scalar )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_e;
        Tpl.Text i_prefix;
      equation
        i_prefix = fun_460(emptyTxt, i_scalar, i_e);
        txt = Tpl.writeText(txt, i_prefix);
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_461(txt, rest, i_varDecls, i_preExp, i_context, i_scalar);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context,
           i_scalar )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_461(txt, rest, i_varDecls, i_preExp, i_context, i_scalar);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_461;

public function daeExpArray
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ARRAY(ty = i_ty, scalar = i_scalar, array = i_array),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_array;
        Boolean i_scalar;
        DAE.ExpType i_ty;
        Integer ret_5;
        Tpl.Text i_params;
        Tpl.Text i_scalarRef;
        Tpl.Text i_scalarPrefix;
        Tpl.Text i_arrayVar;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_arrayVar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_scalarPrefix = fun_458(emptyTxt, i_scalar);
        i_scalarRef = fun_459(emptyTxt, i_scalar);
        i_params = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_params, i_varDecls, i_preExp) = lm_461(i_params, i_array, i_varDecls, i_preExp, i_context, i_scalar);
        i_params = Tpl.popIter(i_params);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("array_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_scalarPrefix);
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        ret_5 = listLength(i_array);
        i_preExp = Tpl.writeStr(i_preExp, intString(ret_5));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_params);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_arrayVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpArray;

protected function lm_463
  input Tpl.Text in_txt;
  input list<list<tuple<DAE.Exp, Boolean>>> in_items;
  input Tpl.Text in_i_vars2;
  input Tpl.Text in_i_promote;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_arrayTypeStr;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_vars2;
  output Tpl.Text out_i_promote;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_vars2, out_i_promote, out_i_varDecls) :=
  matchcontinue(in_txt, in_items, in_i_vars2, in_i_promote, in_i_context, in_i_varDecls, in_i_arrayTypeStr)
    local
      Tpl.Text txt;
      Tpl.Text i_vars2;
      Tpl.Text i_promote;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;
      Tpl.Text i_arrayTypeStr;

    case ( txt,
           {},
           i_vars2,
           i_promote,
           _,
           i_varDecls,
           _ )
      then (txt, i_vars2, i_promote, i_varDecls);

    case ( txt,
           i_row :: rest,
           i_vars2,
           i_promote,
           i_context,
           i_varDecls,
           i_arrayTypeStr )
      local
        list<list<tuple<DAE.Exp, Boolean>>> rest;
        list<tuple<DAE.Exp, Boolean>> i_row;
        Integer ret_2;
        Tpl.Text i_vars;
        Tpl.Text i_tmp;
      equation
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        (i_vars, i_promote, i_varDecls) = daeExpMatrixRow(emptyTxt, i_row, Tpl.textString(i_arrayTypeStr), i_context, i_promote, i_varDecls);
        i_vars2 = Tpl.writeTok(i_vars2, Tpl.ST_STRING(", &"));
        i_vars2 = Tpl.writeText(i_vars2, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("cat_alloc_"));
        txt = Tpl.writeText(txt, i_arrayTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(2, &"));
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = listLength(i_row);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeText(txt, i_vars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_vars2, i_promote, i_varDecls) = lm_463(txt, rest, i_vars2, i_promote, i_context, i_varDecls, i_arrayTypeStr);
      then (txt, i_vars2, i_promote, i_varDecls);

    case ( txt,
           _ :: rest,
           i_vars2,
           i_promote,
           i_context,
           i_varDecls,
           i_arrayTypeStr )
      local
        list<list<tuple<DAE.Exp, Boolean>>> rest;
      equation
        (txt, i_vars2, i_promote, i_varDecls) = lm_463(txt, rest, i_vars2, i_promote, i_context, i_varDecls, i_arrayTypeStr);
      then (txt, i_vars2, i_promote, i_varDecls);
  end matchcontinue;
end lm_463;

public function daeExpMatrix
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.MATRIX(scalar = {{}}, ty = i_ty),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_tmp;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", 2, 0, 1);"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.MATRIX(scalar = {}, ty = i_ty),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_tmp;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", 2, 0, 1);"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           (i_m as DAE.MATRIX(ty = i_m_ty, scalar = i_m_scalar)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<list<tuple<DAE.Exp, Boolean>>> i_m_scalar;
        DAE.ExpType i_m_ty;
        DAE.Exp i_m;
        Integer ret_5;
        Tpl.Text i_tmp;
        Tpl.Text i_catAlloc;
        Tpl.Text i_promote;
        Tpl.Text i_vars2;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_m_ty);
        i_vars2 = emptyTxt;
        i_promote = emptyTxt;
        i_catAlloc = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_catAlloc, i_vars2, i_promote, i_varDecls) = lm_463(i_catAlloc, i_m_scalar, i_vars2, i_promote, i_context, i_varDecls, i_arrayTypeStr);
        i_catAlloc = Tpl.popIter(i_catAlloc);
        i_preExp = Tpl.writeText(i_preExp, i_promote);
        i_preExp = Tpl.writeText(i_preExp, i_catAlloc);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cat_alloc_"));
        i_preExp = Tpl.writeText(i_preExp, i_arrayTypeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(1, &"));
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        ret_5 = listLength(i_m_scalar);
        i_preExp = Tpl.writeStr(i_preExp, intString(ret_5));
        i_preExp = Tpl.writeText(i_preExp, i_vars2);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMatrix;

protected function fun_465
  input Tpl.Text in_txt;
  input Boolean in_i_b;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_b)
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
end fun_465;

protected function fun_466
  input Tpl.Text in_txt;
  input Boolean in_i_b;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_b)
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
end fun_466;

protected function lm_467
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Boolean>> in_items;
  input Tpl.Text in_i_varLstStr;
  input String in_i_arrayTypeStr;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varLstStr;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varLstStr, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varLstStr, in_i_arrayTypeStr, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varLstStr;
      String i_arrayTypeStr;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varLstStr,
           _,
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varLstStr, i_varDecls, i_preExp);

    case ( txt,
           (i_col as (i_e, i_b)) :: rest,
           i_varLstStr,
           i_arrayTypeStr,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Boolean>> rest;
        Boolean i_b;
        DAE.Exp i_e;
        tuple<DAE.Exp, Boolean> i_col;
        Tpl.Text i_tmp;
        Tpl.Text i_expVar;
        Tpl.Text i_scalarRefStr;
        Tpl.Text i_scalarStr;
      equation
        i_scalarStr = fun_465(emptyTxt, i_b);
        i_scalarRefStr = fun_466(emptyTxt, i_b);
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, i_arrayTypeStr, i_varDecls);
        i_varLstStr = Tpl.writeTok(i_varLstStr, Tpl.ST_STRING(", &"));
        i_varLstStr = Tpl.writeText(i_varLstStr, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("promote_"));
        txt = Tpl.writeText(txt, i_scalarStr);
        txt = Tpl.writeStr(txt, i_arrayTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, i_scalarRefStr);
        txt = Tpl.writeText(txt, i_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", 2, &"));
        txt = Tpl.writeText(txt, i_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, i_varLstStr, i_varDecls, i_preExp) = lm_467(txt, rest, i_varLstStr, i_arrayTypeStr, i_varDecls, i_preExp, i_context);
      then (txt, i_varLstStr, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varLstStr,
           i_arrayTypeStr,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<tuple<DAE.Exp, Boolean>> rest;
      equation
        (txt, i_varLstStr, i_varDecls, i_preExp) = lm_467(txt, rest, i_varLstStr, i_arrayTypeStr, i_varDecls, i_preExp, i_context);
      then (txt, i_varLstStr, i_varDecls, i_preExp);
  end matchcontinue;
end lm_467;

public function daeExpMatrixRow
  input Tpl.Text txt;
  input list<tuple<DAE.Exp, Boolean>> i_row;
  input String i_arrayTypeStr;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_preExp2;
  Tpl.Text i_varLstStr;
algorithm
  i_varLstStr := emptyTxt;
  i_preExp2 := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_preExp2, i_varLstStr, out_i_varDecls, out_i_preExp) := lm_467(i_preExp2, i_row, i_varLstStr, i_arrayTypeStr, i_varDecls, i_preExp, i_context);
  i_preExp2 := Tpl.popIter(i_preExp2);
  i_preExp2 := Tpl.writeTok(i_preExp2, Tpl.ST_NEW_LINE());
  out_i_preExp := Tpl.writeText(out_i_preExp, i_preExp2);
  out_txt := Tpl.writeText(txt, i_varLstStr);
end daeExpMatrixRow;

protected function fun_469
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;
  input Tpl.Text in_i_preExp;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_expVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_ty, in_i_preExp, in_i_exp, in_i_varDecls, in_i_expVar)
    local
      Tpl.Text txt;
      Tpl.Text i_preExp;
      DAE.Exp i_exp;
      Tpl.Text i_varDecls;
      Tpl.Text i_expVar;

    case ( txt,
           DAE.ET_INT(),
           i_preExp,
           _,
           i_varDecls,
           i_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_integer)"));
        txt = Tpl.writeText(txt, i_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           i_preExp,
           _,
           i_varDecls,
           i_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_real)"));
        txt = Tpl.writeText(txt, i_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty),
           i_preExp,
           i_exp,
           i_varDecls,
           i_expVar )
      local
        DAE.ExpType i_ty;
        Tpl.Text i_from;
        Tpl.Text i_to;
        Tpl.Text i_tvar;
        Tpl.Text i_arrayTypeStr;
      equation
        i_arrayTypeStr = expTypeArray(emptyTxt, i_ty);
        (i_tvar, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_arrayTypeStr), i_varDecls);
        i_to = expTypeShort(emptyTxt, i_ty);
        i_from = expTypeFromExpShort(emptyTxt, i_exp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("cast_"));
        i_preExp = Tpl.writeText(i_preExp, i_from);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("_array_to_"));
        i_preExp = Tpl.writeText(i_preExp, i_to);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("(&"));
        i_preExp = Tpl.writeText(i_preExp, i_expVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", &"));
        i_preExp = Tpl.writeText(i_preExp, i_tvar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tvar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_preExp,
           _,
           i_varDecls,
           _ )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_469;

public function daeExpCast
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CAST(exp = i_exp, ty = i_ty),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.ExpType i_ty;
        DAE.Exp i_exp;
        Tpl.Text i_expVar;
      equation
        (i_expVar, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (txt, i_preExp, i_varDecls) = fun_469(txt, i_ty, i_preExp, i_exp, i_varDecls, i_expVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCast;

protected function fun_471
  input Tpl.Text in_txt;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_arrName;
  input list<DAE.Exp> in_i_subs;
  input DAE.ExpType in_i_cref_ty;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_context, in_i_varDecls, in_i_preExp, in_i_arrName, in_i_subs, in_i_cref_ty)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      Tpl.Text i_arrName;
      list<DAE.Exp> i_subs;
      DAE.ExpType i_cref_ty;

    case ( txt,
           (i_context as SimCode.SIMULATION(genDiscrete = _)),
           i_varDecls,
           i_preExp,
           i_arrName,
           i_subs,
           i_cref_ty )
      local
        SimCode.Context i_context;
      equation
        (txt, i_preExp, i_varDecls) = arrayScalarRhs(txt, i_cref_ty, i_subs, Tpl.textString(i_arrName), i_context, i_preExp, i_varDecls);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _,
           i_varDecls,
           i_preExp,
           i_arrName,
           _,
           _ )
      equation
        txt = Tpl.writeText(txt, i_arrName);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_471;

public function daeExpAsub
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ASUB(exp = DAE.RANGE(ty = i_t), sub = {i_idx}),
           _,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_idx;
        DAE.ExpType i_t;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ASUB_EASY_CASE"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}), sub = {DAE.ICONST(integer = i_k)}), sub = {DAE.ICONST(integer = i_l)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_l;
        Integer i_k;
        Integer i_j;
        Integer i_i;
        DAE.Exp i_e;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_4D(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_j));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_k));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_l));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}), sub = {DAE.ICONST(integer = i_k)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_k;
        Integer i_j;
        Integer i_i;
        DAE.Exp i_e;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_3D(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_j));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_k));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_j;
        Integer i_i;
        DAE.Exp i_e;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_2D(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_j));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Integer i_i;
        DAE.Exp i_e;
        Tpl.Text i_typeShort;
        Tpl.Text i_e1;
      equation
        (i_e1, i_preExp, i_varDecls) = daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        i_typeShort = expTypeFromExpShort(emptyTxt, i_e);
        txt = Tpl.writeText(txt, i_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get(&"));
        txt = Tpl.writeText(txt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ASUB(exp = (i_cref as DAE.CREF(ty = i_cref_ty)), sub = i_subs),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_subs;
        DAE.ExpType i_cref_ty;
        DAE.Exp i_cref;
        DAE.Exp ret_1;
        Tpl.Text i_arrName;
      equation
        ret_1 = SimCode.buildCrefExpFromAsub(i_cref, i_subs);
        (i_arrName, i_preExp, i_varDecls) = daeExpCrefRhs(emptyTxt, ret_1, i_context, i_preExp, i_varDecls);
        (txt, i_varDecls, i_preExp) = fun_471(txt, i_context, i_varDecls, i_preExp, i_arrName, i_subs, i_cref_ty);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("OTHER_ASUB"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpAsub;

public function daeExpSize
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.SIZE(exp = (i_exp as DAE.CREF(ty = i_exp_ty)), sz = SOME(i_dim)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_dim;
        DAE.ExpType i_exp_ty;
        DAE.Exp i_exp;
        Tpl.Text i_typeStr;
        Tpl.Text i_resVar;
        Tpl.Text i_dimPart;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_exp, i_context, i_preExp, i_varDecls);
        (i_dimPart, i_preExp, i_varDecls) = daeExp(emptyTxt, i_dim, i_context, i_preExp, i_varDecls);
        (i_resVar, i_varDecls) = tempDecl(emptyTxt, "size_t", i_varDecls);
        i_typeStr = expTypeArray(emptyTxt, i_exp_ty);
        i_preExp = Tpl.writeText(i_preExp, i_resVar);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = size_of_dimension_"));
        i_preExp = Tpl.writeText(i_preExp, i_typeStr);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("("));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_dimPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_resVar);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size(X) not implemented"));
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpSize;

protected function fun_474
  input Tpl.Text in_txt;
  input String in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
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
end fun_474;

public function daeExpReduction
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           (i_exp as DAE.REDUCTION(path = Absyn.IDENT(name = i_op), expr = i_expr)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_expr;
        Absyn.Ident i_op;
        DAE.Exp i_exp;
        Tpl.Text i_body;
        String str_7;
        Tpl.Text i_cast;
        Tpl.Text i_tmpExpVar;
        Tpl.Text i_tmpExpPre;
        Tpl.Text i_res;
        Tpl.Text i_startValue;
        Tpl.Text i_accFun;
        Tpl.Text i_identType;
      equation
        i_identType = expTypeFromExpModelica(emptyTxt, i_expr);
        i_accFun = daeExpReductionFnName(emptyTxt, i_op, Tpl.textString(i_identType));
        i_startValue = daeExpReductionStartValue(emptyTxt, i_op, Tpl.textString(i_identType));
        (i_res, i_varDecls) = tempDecl(emptyTxt, Tpl.textString(i_identType), i_varDecls);
        i_tmpExpPre = emptyTxt;
        (i_tmpExpVar, i_tmpExpPre, i_varDecls) = daeExp(emptyTxt, i_expr, i_context, i_tmpExpPre, i_varDecls);
        str_7 = Tpl.textString(i_accFun);
        i_cast = fun_474(emptyTxt, str_7);
        i_body = Tpl.writeText(emptyTxt, i_tmpExpPre);
        i_body = Tpl.softNewLine(i_body);
        i_body = Tpl.writeText(i_body, i_res);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING(" = "));
        i_body = Tpl.writeText(i_body, i_accFun);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("("));
        i_body = Tpl.writeText(i_body, i_cast);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("("));
        i_body = Tpl.writeText(i_body, i_res);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("), "));
        i_body = Tpl.writeText(i_body, i_cast);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("("));
        i_body = Tpl.writeText(i_body, i_tmpExpVar);
        i_body = Tpl.writeTok(i_body, Tpl.ST_STRING("));"));
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_startValue);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        (i_preExp, i_body, i_varDecls) = daeExpReductionLoop(i_preExp, i_exp, i_body, i_context, i_varDecls);
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpReduction;

public function daeExpReductionLoop
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input Tpl.Text in_i_body;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_body;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_body, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_body, in_i_context, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_body;
      SimCode.Context i_context;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.REDUCTION(range = (i_range as DAE.RANGE(ty = i_range_ty)), expr = i_expr, ident = i_ident),
           i_body,
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        DAE.Exp i_expr;
        DAE.ExpType i_range_ty;
        DAE.Exp i_range;
        Tpl.Text i_identTypeShort;
        Tpl.Text i_identType;
      equation
        i_identType = expTypeModelica(emptyTxt, i_range_ty);
        i_identTypeShort = expTypeFromExpShort(emptyTxt, i_expr);
        (txt, i_body, i_varDecls) = algStmtForRange_impl(txt, i_range, i_ident, Tpl.textString(i_identType), Tpl.textString(i_identTypeShort), i_body, i_context, i_varDecls);
      then (txt, i_body, i_varDecls);

    case ( txt,
           DAE.REDUCTION(range = i_range, expr = i_expr, ident = i_ident),
           i_body,
           i_context,
           i_varDecls )
      local
        DAE.Ident i_ident;
        DAE.Exp i_expr;
        DAE.Exp i_range;
        Tpl.Text i_arrayType;
        Tpl.Text i_identType;
      equation
        i_identType = expTypeFromExpModelica(emptyTxt, i_expr);
        i_arrayType = expTypeFromExpArray(emptyTxt, i_expr);
        (txt, i_body, i_varDecls) = algStmtForGeneric_impl(txt, i_range, i_ident, Tpl.textString(i_identType), Tpl.textString(i_arrayType), false, i_body, i_context, i_varDecls);
      then (txt, i_body, i_varDecls);

    case ( txt,
           _,
           i_body,
           _,
           i_varDecls )
      then (txt, i_body, i_varDecls);
  end matchcontinue;
end daeExpReductionLoop;

protected function fun_477
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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
end fun_477;

protected function fun_478
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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
end fun_478;

public function daeExpReductionFnName
  input Tpl.Text in_txt;
  input String in_i_reduction__op;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_reduction__op, in_i_type)
    local
      Tpl.Text txt;
      String i_type;

    case ( txt,
           "sum",
           i_type )
      equation
        txt = fun_477(txt, i_type);
      then txt;

    case ( txt,
           "product",
           i_type )
      equation
        txt = fun_478(txt, i_type);
      then txt;

    case ( txt,
           i_reduction__op,
           _ )
      local
        String i_reduction__op;
      equation
        txt = Tpl.writeStr(txt, i_reduction__op);
      then txt;
  end matchcontinue;
end daeExpReductionFnName;

protected function fun_480
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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
end fun_480;

protected function fun_481
  input Tpl.Text in_txt;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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
end fun_481;

public function daeExpReductionStartValue
  input Tpl.Text in_txt;
  input String in_i_reduction__op;
  input String in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_reduction__op, in_i_type)
    local
      Tpl.Text txt;
      String i_type;

    case ( txt,
           "min",
           i_type )
      equation
        txt = fun_480(txt, i_type);
      then txt;

    case ( txt,
           "max",
           i_type )
      equation
        txt = fun_481(txt, i_type);
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

protected function lm_483
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_i_preExpInner;
  input Tpl.Text in_i_varDeclsInner;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExpInner;
  output Tpl.Text out_i_varDeclsInner;
algorithm
  (out_txt, out_i_preExpInner, out_i_varDeclsInner) :=
  matchcontinue(in_txt, in_items, in_i_preExpInner, in_i_varDeclsInner)
    local
      Tpl.Text txt;
      Tpl.Text i_preExpInner;
      Tpl.Text i_varDeclsInner;

    case ( txt,
           {},
           i_preExpInner,
           i_varDeclsInner )
      then (txt, i_preExpInner, i_varDeclsInner);

    case ( txt,
           i_var :: rest,
           i_preExpInner,
           i_varDeclsInner )
      local
        list<SimCode.Variable> rest;
        SimCode.Variable i_var;
      equation
        (txt, i_varDeclsInner, i_preExpInner) = varInit(txt, i_var, "", 0, i_varDeclsInner, i_preExpInner);
        (txt, i_preExpInner, i_varDeclsInner) = lm_483(txt, rest, i_preExpInner, i_varDeclsInner);
      then (txt, i_preExpInner, i_varDeclsInner);

    case ( txt,
           _ :: rest,
           i_preExpInner,
           i_varDeclsInner )
      local
        list<SimCode.Variable> rest;
      equation
        (txt, i_preExpInner, i_varDeclsInner) = lm_483(txt, rest, i_preExpInner, i_varDeclsInner);
      then (txt, i_preExpInner, i_varDeclsInner);
  end matchcontinue;
end lm_483;

protected function lm_484
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_i_varDeclsInner;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDeclsInner;
algorithm
  (out_txt, out_i_varDeclsInner) :=
  matchcontinue(in_txt, in_items, in_i_varDeclsInner, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDeclsInner;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDeclsInner,
           _ )
      then (txt, i_varDeclsInner);

    case ( txt,
           i_stmt :: rest,
           i_varDeclsInner,
           i_context )
      local
        list<DAE.Statement> rest;
        DAE.Statement i_stmt;
      equation
        (txt, i_varDeclsInner) = algStatement(txt, i_stmt, i_context, i_varDeclsInner);
        txt = Tpl.nextIter(txt);
        (txt, i_varDeclsInner) = lm_484(txt, rest, i_varDeclsInner, i_context);
      then (txt, i_varDeclsInner);

    case ( txt,
           _ :: rest,
           i_varDeclsInner,
           i_context )
      local
        list<DAE.Statement> rest;
      equation
        (txt, i_varDeclsInner) = lm_484(txt, rest, i_varDeclsInner, i_context);
      then (txt, i_varDeclsInner);
  end matchcontinue;
end lm_484;

protected function fun_485
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_preExp) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;

    case ( txt,
           (i_exp as DAE.VALUEBLOCK(ty = i_ty, body = i_body, result = i_result)),
           i_context,
           i_preExp )
      local
        DAE.Exp i_result;
        list<DAE.Statement> i_body;
        DAE.ExpType i_ty;
        DAE.Exp i_exp;
        Tpl.Text i_expPart;
        Tpl.Text i_stmts;
        Tpl.Text txt_7;
        Tpl.Text i_res;
        Tpl.Text i_resType;
        list<SimCode.Variable> ret_4;
        Tpl.Text i_0__;
        Tpl.Text i_varDeclsInner;
        Tpl.Text i_preExpRes;
        Tpl.Text i_preExpInner;
      equation
        i_preExpInner = emptyTxt;
        i_preExpRes = emptyTxt;
        i_varDeclsInner = emptyTxt;
        ret_4 = SimCode.valueblockVars(i_exp);
        (i_0__, i_preExpInner, i_varDeclsInner) = lm_483(emptyTxt, ret_4, i_preExpInner, i_varDeclsInner);
        i_resType = expTypeModelica(emptyTxt, i_ty);
        txt_7 = expTypeModelica(emptyTxt, i_ty);
        (i_res, i_preExp) = tempDecl(emptyTxt, Tpl.textString(txt_7), i_preExp);
        i_stmts = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_stmts, i_varDeclsInner) = lm_484(i_stmts, i_body, i_varDeclsInner, i_context);
        i_stmts = Tpl.popIter(i_stmts);
        (i_expPart, i_preExpRes, i_varDeclsInner) = daeExp(emptyTxt, i_result, i_context, i_preExpRes, i_varDeclsInner);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE("{\n"));
        i_preExp = Tpl.pushBlock(i_preExp, Tpl.BT_INDENT(2));
        i_preExp = Tpl.writeText(i_preExp, i_varDeclsInner);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_preExpInner);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_stmts);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_preExpRes);
        i_preExp = Tpl.softNewLine(i_preExp);
        i_preExp = Tpl.writeText(i_preExp, i_res);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_LINE(";\n"));
        i_preExp = Tpl.popBlock(i_preExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("}"));
        txt = Tpl.writeText(txt, i_res);
      then (txt, i_preExp);

    case ( txt,
           _,
           _,
           i_preExp )
      then (txt, i_preExp);
  end matchcontinue;
end fun_485;

public function daeExpValueblock
  input Tpl.Text txt;
  input DAE.Exp i_exp;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp) := fun_485(txt, i_exp, i_context, i_preExp);
  out_i_varDecls := i_varDecls;
end daeExpValueblock;

protected function lm_487
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExp(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_487(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_487(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_487;

public function arrayScalarRhs
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input list<DAE.Exp> i_subs;
  input String i_arrName;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  Tpl.Text i_dimsValuesStr;
  Integer ret_2;
  Tpl.Text i_dimsLenStr;
  Tpl.Text i_arrayType;
algorithm
  i_arrayType := expTypeArray(emptyTxt, i_ty);
  ret_2 := listLength(i_subs);
  i_dimsLenStr := Tpl.writeStr(emptyTxt, intString(ret_2));
  i_dimsValuesStr := Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_dimsValuesStr, out_i_varDecls, out_i_preExp) := lm_487(i_dimsValuesStr, i_subs, i_varDecls, i_preExp, i_context);
  i_dimsValuesStr := Tpl.popIter(i_dimsValuesStr);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("(*"));
  out_txt := Tpl.writeText(out_txt, i_arrayType);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_element_addr(&"));
  out_txt := Tpl.writeStr(out_txt, i_arrName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(", "));
  out_txt := Tpl.writeText(out_txt, i_dimsLenStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(", "));
  out_txt := Tpl.writeText(out_txt, i_dimsValuesStr);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("))"));
end arrayScalarRhs;

public function daeExpList
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.LIST(valList = i_valList),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_valList;
        Tpl.Text i_expPart;
        Tpl.Text i_tmp;
      equation
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        (i_expPart, i_preExp, i_varDecls) = daeExpListToCons(emptyTxt, i_valList, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_expPart);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(";"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpList;

public function daeExpListToCons
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_listItems;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_listItems, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           {},
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_nil()"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           i_e :: i_rest,
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_rest;
        DAE.Exp i_e;
        Tpl.Text i_restList;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExpMetaHelperConstant(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        (i_restList, i_preExp, i_varDecls) = daeExpListToCons(emptyTxt, i_rest, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_cons("));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_restList);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpListToCons;

public function daeExpCons
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.CONS(car = i_car, cdr = i_cdr),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_cdr;
        DAE.Exp i_car;
        Tpl.Text i_cdrExp;
        Tpl.Text i_carExp;
        Tpl.Text i_tmp;
      equation
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        (i_carExp, i_preExp, i_varDecls) = daeExpMetaHelperConstant(emptyTxt, i_car, i_context, i_preExp, i_varDecls);
        (i_cdrExp, i_preExp, i_varDecls) = daeExp(emptyTxt, i_cdr, i_context, i_preExp, i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = mmc_mk_cons("));
        i_preExp = Tpl.writeText(i_preExp, i_carExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(", "));
        i_preExp = Tpl.writeText(i_preExp, i_cdrExp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpCons;

protected function lm_492
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_e :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_e;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaHelperConstant(txt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_492(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_492(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_492;

public function daeExpMetaTuple
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.META_TUPLE(listExp = i_listExp),
           i_context,
           i_preExp,
           i_varDecls )
      local
        list<DAE.Exp> i_listExp;
        Tpl.Text i_tmp;
        Tpl.Text i_args;
        Integer ret_1;
        Tpl.Text i_start;
      equation
        ret_1 = listLength(i_listExp);
        i_start = daeExpMetaHelperBoxStart(emptyTxt, ret_1);
        i_args = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (i_args, i_varDecls, i_preExp) = lm_492(i_args, i_listExp, i_varDecls, i_preExp, i_context);
        i_args = Tpl.popIter(i_args);
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = mmc_mk_box"));
        i_preExp = Tpl.writeText(i_preExp, i_start);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING("0, "));
        i_preExp = Tpl.writeText(i_preExp, i_args);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(");"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMetaTuple;

public function daeExpMetaOption
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.META_OPTION(exp = NONE),
           _,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_none()"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.META_OPTION(exp = SOME(i_e)),
           i_context,
           i_preExp,
           i_varDecls )
      local
        DAE.Exp i_e;
        Tpl.Text i_expPart;
      equation
        (i_expPart, i_preExp, i_varDecls) = daeExpMetaHelperConstant(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_some("));
        txt = Tpl.writeText(txt, i_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMetaOption;

protected function lm_495
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_exp :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
        DAE.Exp i_exp;
      equation
        (txt, i_preExp, i_varDecls) = daeExpMetaHelperConstant(txt, i_exp, i_context, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_495(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_495(txt, rest, i_varDecls, i_preExp, i_context);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_495;

protected function fun_496
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_args;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input SimCode.Context in_i_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_args, in_i_varDecls, in_i_preExp, in_i_context)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      SimCode.Context i_context;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_args,
           i_varDecls,
           i_preExp,
           i_context )
      local
        list<DAE.Exp> i_args;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_495(txt, i_args, i_varDecls, i_preExp, i_context);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_496;

public function daeExpMetarecordcall
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input SimCode.Context in_i_context;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_exp, in_i_context, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context i_context;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.METARECORDCALL(index = i_index, args = i_args, path = i_path),
           i_context,
           i_preExp,
           i_varDecls )
      local
        Absyn.Path i_path;
        list<DAE.Exp> i_args;
        Integer i_index;
        Tpl.Text i_tmp;
        Integer ret_5;
        Integer ret_4;
        Tpl.Text i_box;
        Tpl.Text i_argsStr;
        Integer ret_1;
        Tpl.Text i_newIndex;
      equation
        ret_1 = SimCode.incrementInt(i_index, 3);
        i_newIndex = Tpl.writeStr(emptyTxt, intString(ret_1));
        (i_argsStr, i_varDecls, i_preExp) = fun_496(emptyTxt, i_args, i_varDecls, i_preExp, i_context);
        i_box = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("mmc_mk_box"));
        ret_4 = listLength(i_args);
        ret_5 = SimCode.incrementInt(ret_4, 1);
        i_box = daeExpMetaHelperBoxStart(i_box, ret_5);
        i_box = Tpl.writeText(i_box, i_newIndex);
        i_box = Tpl.writeTok(i_box, Tpl.ST_STRING(", &"));
        i_box = underscorePath(i_box, i_path);
        i_box = Tpl.writeTok(i_box, Tpl.ST_STRING("__desc"));
        i_box = Tpl.writeText(i_box, i_argsStr);
        i_box = Tpl.writeTok(i_box, Tpl.ST_STRING(")"));
        (i_tmp, i_varDecls) = tempDecl(emptyTxt, "modelica_metatype", i_varDecls);
        i_preExp = Tpl.writeText(i_preExp, i_tmp);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(" = "));
        i_preExp = Tpl.writeText(i_preExp, i_box);
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_STRING(";"));
        i_preExp = Tpl.writeTok(i_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, i_tmp);
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           _,
           i_preExp,
           i_varDecls )
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end daeExpMetarecordcall;

public function daeExpMetaHelperConstant
  input Tpl.Text txt;
  input DAE.Exp i_e;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
protected
  DAE.ExpType ret_1;
  Tpl.Text i_expPart;
algorithm
  (i_expPart, out_i_preExp, out_i_varDecls) := daeExp(emptyTxt, i_e, i_context, i_preExp, i_varDecls);
  ret_1 := Exp.typeof(i_e);
  (out_txt, i_expPart, out_i_preExp, out_i_varDecls) := daeExpMetaHelperConstantNameType(txt, i_expPart, ret_1, out_i_preExp, out_i_varDecls);
end daeExpMetaHelperConstant;

protected function lm_499
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varname;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_items, in_i_varDecls, in_i_preExp, in_i_varname)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      Tpl.Text i_varname;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           (i_v as DAE.COMPLEX_VAR(name = i_cvname, tp = i_tp)) :: rest,
           i_varDecls,
           i_preExp,
           i_varname )
      local
        list<DAE.ExpVar> rest;
        DAE.ExpType i_tp;
        String i_cvname;
        DAE.ExpVar i_v;
        Tpl.Text i_nameText;
      equation
        i_nameText = Tpl.writeText(emptyTxt, i_varname);
        i_nameText = Tpl.writeTok(i_nameText, Tpl.ST_STRING("."));
        i_nameText = Tpl.writeStr(i_nameText, i_cvname);
        (txt, i_nameText, i_preExp, i_varDecls) = daeExpMetaHelperConstantNameType(txt, i_nameText, i_tp, i_preExp, i_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, i_varDecls, i_preExp) = lm_499(txt, rest, i_varDecls, i_preExp, i_varname);
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           _ :: rest,
           i_varDecls,
           i_preExp,
           i_varname )
      local
        list<DAE.ExpVar> rest;
      equation
        (txt, i_varDecls, i_preExp) = lm_499(txt, rest, i_varDecls, i_preExp, i_varname);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end lm_499;

protected function fun_500
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_i_varLst;
  input Tpl.Text in_i_varDecls;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varname;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
  output Tpl.Text out_i_preExp;
algorithm
  (out_txt, out_i_varDecls, out_i_preExp) :=
  matchcontinue(in_txt, in_i_varLst, in_i_varDecls, in_i_preExp, in_i_varname)
    local
      Tpl.Text txt;
      Tpl.Text i_varDecls;
      Tpl.Text i_preExp;
      Tpl.Text i_varname;

    case ( txt,
           {},
           i_varDecls,
           i_preExp,
           _ )
      then (txt, i_varDecls, i_preExp);

    case ( txt,
           i_varLst,
           i_varDecls,
           i_preExp,
           i_varname )
      local
        list<DAE.ExpVar> i_varLst;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, i_varDecls, i_preExp) = lm_499(txt, i_varLst, i_varDecls, i_preExp, i_varname);
        txt = Tpl.popIter(txt);
      then (txt, i_varDecls, i_preExp);
  end matchcontinue;
end fun_500;

protected function fun_501
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type;
  input Tpl.Text in_i_varname;
  input Tpl.Text in_i_preExp;
  input Tpl.Text in_i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) :=
  matchcontinue(in_txt, in_i_type, in_i_varname, in_i_preExp, in_i_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text i_varname;
      Tpl.Text i_preExp;
      Tpl.Text i_varDecls;

    case ( txt,
           DAE.ET_INT(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_BOOL(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_STRING(),
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon("));
        txt = Tpl.writeText(txt, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(name = i_cname, varLst = i_varLst),
           i_varname,
           i_preExp,
           i_varDecls )
      local
        list<DAE.ExpVar> i_varLst;
        Absyn.Path i_cname;
        Tpl.Text i_args;
        Integer ret_2;
        Integer ret_1;
        Tpl.Text i_start;
      equation
        ret_1 = listLength(i_varLst);
        ret_2 = SimCode.incrementInt(ret_1, 1);
        i_start = daeExpMetaHelperBoxStart(emptyTxt, ret_2);
        (i_args, i_varDecls, i_preExp) = fun_500(emptyTxt, i_varLst, i_varDecls, i_preExp, i_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box"));
        txt = Tpl.writeText(txt, i_start);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("2, &"));
        txt = underscorePath(txt, i_cname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc"));
        txt = Tpl.writeText(txt, i_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, i_preExp, i_varDecls);

    case ( txt,
           _,
           i_varname,
           i_preExp,
           i_varDecls )
      equation
        txt = Tpl.writeText(txt, i_varname);
      then (txt, i_preExp, i_varDecls);
  end matchcontinue;
end fun_501;

public function daeExpMetaHelperConstantNameType
  input Tpl.Text txt;
  input Tpl.Text i_varname;
  input DAE.ExpType i_type;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varname;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  (out_txt, out_i_preExp, out_i_varDecls) := fun_501(txt, i_type, i_varname, i_preExp, i_varDecls);
  out_i_varname := i_varname;
end daeExpMetaHelperConstantNameType;

public function daeExpMetaHelperBoxStart
  input Tpl.Text in_txt;
  input Integer in_i_numVariables;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_numVariables)
    local
      Tpl.Text txt;

    case ( txt,
           (i_numVariables as 0) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 1) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 2) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 3) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 4) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 5) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 6) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 7) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 8) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 9) )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           i_numVariables )
      local
        Integer i_numVariables;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
      then txt;
  end matchcontinue;
end daeExpMetaHelperBoxStart;

public function tempDecl
  input Tpl.Text txt;
  input String i_ty;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_varDecls;
protected
  Integer ret_1;
  Tpl.Text i_newVar;
algorithm
  i_newVar := Tpl.writeTok(emptyTxt, Tpl.ST_STRING("tmp"));
  ret_1 := System.tmpTick();
  i_newVar := Tpl.writeStr(i_newVar, intString(ret_1));
  out_i_varDecls := Tpl.writeStr(i_varDecls, i_ty);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(" "));
  out_i_varDecls := Tpl.writeText(out_i_varDecls, i_newVar);
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_STRING(";"));
  out_i_varDecls := Tpl.writeTok(out_i_varDecls, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, i_newVar);
end tempDecl;

protected function fun_505
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_i_instDims;
  input DAE.ExpType in_i_var_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_instDims, in_i_var_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_var_ty;

    case ( txt,
           {},
           i_var_ty )
      equation
        txt = expTypeArrayIf(txt, i_var_ty);
      then txt;

    case ( txt,
           _,
           i_var_ty )
      equation
        txt = expTypeArray(txt, i_var_ty);
      then txt;
  end matchcontinue;
end fun_505;

public function varType
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(instDims = i_instDims, ty = i_var_ty)) )
      local
        DAE.ExpType i_var_ty;
        list<DAE.Exp> i_instDims;
        SimCode.Variable i_var;
      equation
        txt = fun_505(txt, i_instDims, i_var_ty);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end varType;

public function varTypeBoxed
  input Tpl.Text in_txt;
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
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
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
    local
      Tpl.Text txt;

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
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
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
           DAE.ET_METAOPTION(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_LIST(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_METATUPLE(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_UNIONTYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_POLYMORPHIC() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_META_ARRAY(ty = _) )
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
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           DAE.ET_OTHER() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("complex"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
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
      local
        Absyn.Path i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_name);
      then txt;

    case ( txt,
           DAE.ET_LIST(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_METATUPLE(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_METAOPTION(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_UNIONTYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_POLYMORPHIC() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_META_ARRAY(ty = _) )
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
  input SimCode.Variable in_i_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty) )
      local
        DAE.ExpType i_ty;
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
  input DAE.ExpType in_i_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type)
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
           DAE.ET_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("array"));
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
      then txt;
  end matchcontinue;
end mmcExpTypeShort;

protected function fun_512
  input Tpl.Text in_txt;
  input Boolean in_i_array;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_array, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           true,
           i_ty )
      equation
        txt = expTypeArray(txt, i_ty);
      then txt;

    case ( txt,
           false,
           i_ty )
      equation
        txt = expTypeModelica(txt, i_ty);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_512;

public function expType
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input Boolean i_array;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_512(txt, i_array, i_ty);
end expType;

public function expTypeModelica
  input Tpl.Text txt;
  input DAE.ExpType i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, i_ty, 2);
end expTypeModelica;

public function expTypeArray
  input Tpl.Text txt;
  input DAE.ExpType i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, i_ty, 3);
end expTypeArray;

public function expTypeArrayIf
  input Tpl.Text txt;
  input DAE.ExpType i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, i_ty, 4);
end expTypeArrayIf;

public function expTypeFromExpShort
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 1);
end expTypeFromExpShort;

public function expTypeFromExpModelica
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 2);
end expTypeFromExpModelica;

public function expTypeFromExpArray
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 3);
end expTypeFromExpArray;

public function expTypeFromExpArrayIf
  input Tpl.Text txt;
  input DAE.Exp i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, i_exp, 4);
end expTypeFromExpArrayIf;

protected function fun_521
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_COMPLEX(name = i_name) )
      local
        Absyn.Path i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_name);
      then txt;

    case ( txt,
           i_ty )
      local
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = expTypeShort(txt, i_ty);
      then txt;
  end matchcontinue;
end fun_521;

protected function fun_522
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = _))) )
      local
        DAE.ExpType i_ty;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = expTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           i_ty )
      local
        DAE.ExpType i_ty;
      equation
        txt = fun_521(txt, i_ty);
      then txt;
  end matchcontinue;
end fun_522;

protected function fun_523
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeShort(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array"));
      then txt;

    case ( txt,
           i_ty )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeFlag(txt, i_ty, 2);
      then txt;
  end matchcontinue;
end fun_523;

protected function fun_524
  input Tpl.Text in_txt;
  input Integer in_i_flag;
  input DAE.ExpType in_i_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag, in_i_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           1,
           i_ty )
      equation
        txt = expTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           2,
           i_ty )
      equation
        txt = fun_522(txt, i_ty);
      then txt;

    case ( txt,
           3,
           i_ty )
      equation
        txt = expTypeShort(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array"));
      then txt;

    case ( txt,
           4,
           i_ty )
      equation
        txt = fun_523(txt, i_ty);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_524;

public function expTypeFlag
  input Tpl.Text txt;
  input DAE.ExpType i_ty;
  input Integer i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_524(txt, i_flag, i_ty);
end expTypeFlag;

protected function fun_526
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
    local
      Tpl.Text txt;

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
end fun_526;

protected function fun_527
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
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
end fun_527;

protected function fun_528
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
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
end fun_528;

protected function fun_529
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
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
end fun_529;

public function expTypeFromExpFlag
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_exp, in_i_flag)
    local
      Tpl.Text txt;
      Integer i_flag;

    case ( txt,
           DAE.ICONST(integer = _),
           i_flag )
      equation
        txt = fun_526(txt, i_flag);
      then txt;

    case ( txt,
           DAE.RCONST(real = _),
           i_flag )
      equation
        txt = fun_527(txt, i_flag);
      then txt;

    case ( txt,
           DAE.SCONST(string = _),
           i_flag )
      equation
        txt = fun_528(txt, i_flag);
      then txt;

    case ( txt,
           DAE.BCONST(bool = _),
           i_flag )
      equation
        txt = fun_529(txt, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.BINARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.UNARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.LBINARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.LUNARY(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           (i_e as DAE.RELATION(operator = i_e_operator)),
           i_flag )
      local
        DAE.Operator i_e_operator;
        DAE.Exp i_e;
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, i_flag);
      then txt;

    case ( txt,
           DAE.IFEXP(expThen = i_expThen),
           i_flag )
      local
        DAE.Exp i_expThen;
      equation
        txt = expTypeFromExpFlag(txt, i_expThen, i_flag);
      then txt;

    case ( txt,
           DAE.CALL(ty = i_ty),
           i_flag )
      local
        DAE.ExpType i_ty;
      equation
        txt = expTypeFlag(txt, i_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.ARRAY(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.MATRIX(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.RANGE(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.CAST(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.CREF(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           (i_c as DAE.CODE(ty = i_c_ty)),
           i_flag )
      local
        DAE.ExpType i_c_ty;
        DAE.Exp i_c;
      equation
        txt = expTypeFlag(txt, i_c_ty, i_flag);
      then txt;

    case ( txt,
           DAE.ASUB(exp = i_exp),
           i_flag )
      local
        DAE.Exp i_exp;
      equation
        txt = expTypeFromExpFlag(txt, i_exp, i_flag);
      then txt;

    case ( txt,
           DAE.REDUCTION(expr = i_expr),
           i_flag )
      local
        DAE.Exp i_expr;
      equation
        txt = expTypeFromExpFlag(txt, i_expr, i_flag);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeFromExpFlag:ERROR"));
      then txt;
  end matchcontinue;
end expTypeFromExpFlag;

protected function fun_531
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
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
end fun_531;

protected function fun_532
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
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
end fun_532;

protected function fun_533
  input Tpl.Text in_txt;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_flag)
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
end fun_533;

public function expTypeFromOpFlag
  input Tpl.Text in_txt;
  input DAE.Operator in_i_op;
  input Integer in_i_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_op, in_i_flag)
    local
      Tpl.Text txt;
      Integer i_flag;

    case ( txt,
           (i_o as DAE.ADD(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UMINUS(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UPLUS(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UMINUS_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.UPLUS_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.ADD_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.ADD_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.ADD_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.SUB_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_SCALAR_PRODUCT(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.MUL_MATRIX_PRODUCT(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.DIV_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_ARRAY_SCALAR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_SCALAR_ARRAY(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_ARR(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.POW_ARR2(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.LESS(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.LESSEQ(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.GREATER(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.GREATEREQ(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.EQUAL(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.NEQUAL(ty = i_o_ty)),
           i_flag )
      local
        DAE.ExpType i_o_ty;
        DAE.Operator i_o;
      equation
        txt = expTypeFlag(txt, i_o_ty, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.AND()),
           i_flag )
      local
        DAE.Operator i_o;
      equation
        txt = fun_531(txt, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.OR()),
           i_flag )
      local
        DAE.Operator i_o;
      equation
        txt = fun_532(txt, i_flag);
      then txt;

    case ( txt,
           (i_o as DAE.NOT()),
           i_flag )
      local
        DAE.Operator i_o;
      equation
        txt = fun_533(txt, i_flag);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeFromOpFlag:ERROR"));
      then txt;
  end matchcontinue;
end expTypeFromOpFlag;

end SimCodeC;