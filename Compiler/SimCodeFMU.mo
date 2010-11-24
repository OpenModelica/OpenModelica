package SimCodeFMU

public import Tpl;

public import SimCode;
public import BackendDAE;
public import System;
public import Absyn;
public import DAE;
public import ClassInf;
public import Util;
public import ComponentReference;
public import Expression;
public import RTOpts;
public import Settings;
public import SimCodeC;

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
           (i_simCode as SimCode.SIMCODE(fileNamePrefix = i_fileNamePrefix)) )
      local
        String i_fileNamePrefix;
        SimCode.SimCode i_simCode;
        Tpl.Text txt_6;
        Tpl.Text txt_5;
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        String ret_1;
        Tpl.Text i_guid;
      equation
        ret_1 = System.getUUIDStr();
        i_guid = Tpl.writeStr(Tpl.emptyTxt, ret_1);
        txt_2 = fmuModelDescriptionFile(Tpl.emptyTxt, i_simCode, Tpl.textString(i_guid));
        Tpl.textFile(txt_2, "modelDescription.xml");
        txt_3 = fmumodel_identifierFile(Tpl.emptyTxt, i_simCode, Tpl.textString(i_guid));
        txt_4 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_4 = Tpl.writeTok(txt_4, Tpl.ST_STRING("_FMU.cpp"));
        Tpl.textFile(txt_3, Tpl.textString(txt_4));
        txt_5 = fmuMakefile(Tpl.emptyTxt, i_simCode);
        txt_6 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_6 = Tpl.writeTok(txt_6, Tpl.ST_STRING("_FMU.makefile"));
        Tpl.textFile(txt_5, Tpl.textString(txt_6));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateModel;

public function fmuModelDescriptionFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;
  input String in_i_guid;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode, in_i_guid)
    local
      Tpl.Text txt;
      String i_guid;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = _)),
           i_guid )
      local
        SimCode.SimCode i_simCode;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"));
        txt = fmiModelDescription(txt, i_simCode, i_guid);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fmuModelDescriptionFile;

public function fmiModelDescription
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;
  input String in_i_guid;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode, in_i_guid)
    local
      Tpl.Text txt;
      String i_guid;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(simulationSettingsOpt = i_simulationSettingsOpt, modelInfo = i_modelInfo)),
           i_guid )
      local
        SimCode.ModelInfo i_modelInfo;
        Option<SimCode.SimulationSettings> i_simulationSettingsOpt;
        SimCode.SimCode i_simCode;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("<fmiModelDescription\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = fmiModelDescriptionAttributes(txt, i_simCode, i_guid);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(">\n"));
        txt = DefaultExperiment(txt, i_simulationSettingsOpt);
        txt = Tpl.softNewLine(txt);
        txt = ModelVariables(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("</fmiModelDescription>"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fmiModelDescription;

public function fmiModelDescriptionAttributes
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;
  input String in_i_guid;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode, in_i_guid)
    local
      Tpl.Text txt;
      String i_guid;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(varInfo = (i_vi as SimCode.VARINFO(numStateVars = i_vi_numStateVars, numZeroCrossings = i_vi_numZeroCrossings)), name = i_modelInfo_name), fileNamePrefix = i_fileNamePrefix),
           i_guid )
      local
        String i_fileNamePrefix;
        Absyn.Path i_modelInfo_name;
        Integer i_vi_numZeroCrossings;
        Integer i_vi_numStateVars;
        SimCode.VarInfo i_vi;
        Tpl.Text i_numberOfEventIndicators;
        Tpl.Text i_numberOfContinuousStates;
        Tpl.Text i_variableNamingConvention;
        Util.DateTime ret_9;
        Tpl.Text i_generationDateAndTime;
        String ret_7;
        Tpl.Text i_generationTool;
        Tpl.Text i_version;
        Tpl.Text i_author;
        Tpl.Text i_description;
        Tpl.Text i_modelIdentifier;
        Tpl.Text i_modelName;
        Tpl.Text i_fmiVersion;
      equation
        i_fmiVersion = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("1.0"));
        i_modelName = SimCodeC.dotPath(Tpl.emptyTxt, i_modelInfo_name);
        i_modelIdentifier = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        i_description = Tpl.emptyTxt;
        i_author = Tpl.emptyTxt;
        i_version = Tpl.emptyTxt;
        i_generationTool = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("OpenModelica Compiler "));
        ret_7 = Settings.getVersionNr();
        i_generationTool = Tpl.writeStr(i_generationTool, ret_7);
        ret_9 = Util.getCurrentDateTime();
        i_generationDateAndTime = xsdateTime(Tpl.emptyTxt, ret_9);
        i_variableNamingConvention = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("structured"));
        i_numberOfContinuousStates = Tpl.writeStr(Tpl.emptyTxt, intString(i_vi_numStateVars));
        i_numberOfEventIndicators = Tpl.writeStr(Tpl.emptyTxt, intString(i_vi_numZeroCrossings));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fmiVersion=\""));
        txt = Tpl.writeText(txt, i_fmiVersion);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "modelName=\""
                                }, false));
        txt = Tpl.writeText(txt, i_modelName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "modelIdentifier=\""
                                }, false));
        txt = Tpl.writeText(txt, i_modelIdentifier);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "guid=\"{"
                                }, false));
        txt = Tpl.writeStr(txt, i_guid);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\"\n",
                                    "generationTool=\""
                                }, false));
        txt = Tpl.writeText(txt, i_generationTool);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "generationDateAndTime=\""
                                }, false));
        txt = Tpl.writeText(txt, i_generationDateAndTime);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "variableNamingConvention=\""
                                }, false));
        txt = Tpl.writeText(txt, i_variableNamingConvention);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "numberOfContinuousStates=\""
                                }, false));
        txt = Tpl.writeText(txt, i_numberOfContinuousStates);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "numberOfEventIndicators=\""
                                }, false));
        txt = Tpl.writeText(txt, i_numberOfEventIndicators);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fmiModelDescriptionAttributes;

public function xsdateTime
  input Tpl.Text in_txt;
  input Util.DateTime in_i_dt;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_dt)
    local
      Tpl.Text txt;

    case ( txt,
           Util.DATETIME(year = i_year, mon = i_mon, mday = i_mday, hour = i_hour, min = i_min, sec = i_sec) )
      local
        Integer i_sec;
        Integer i_min;
        Integer i_hour;
        Integer i_mday;
        Integer i_mon;
        Integer i_year;
      equation
        txt = Tpl.writeStr(txt, intString(i_year));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-"));
        txt = Tpl.writeStr(txt, intString(i_mon));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-"));
        txt = Tpl.writeStr(txt, intString(i_mday));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("T"));
        txt = Tpl.writeStr(txt, intString(i_hour));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"));
        txt = Tpl.writeStr(txt, intString(i_min));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"));
        txt = Tpl.writeStr(txt, intString(i_sec));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Z"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end xsdateTime;

public function UnitDefinitions
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "<UnitDefinitions>\n",
                                    "</UnitDefinitions>"
                                }, false));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end UnitDefinitions;

public function TypeDefinitions
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "<TypeDefinitions>\n",
                                    "</TypeDefinitions>"
                                }, false));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end TypeDefinitions;

public function DefaultExperiment
  input Tpl.Text in_txt;
  input Option<SimCode.SimulationSettings> in_i_simulationSettingsOpt;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simulationSettingsOpt)
    local
      Tpl.Text txt;

    case ( txt,
           SOME(i_v) )
      local
        SimCode.SimulationSettings i_v;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<DefaultExperiment "));
        txt = DefaultExperimentAttribute(txt, i_v);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/>"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end DefaultExperiment;

public function DefaultExperimentAttribute
  input Tpl.Text in_txt;
  input SimCode.SimulationSettings in_i_simulationSettings;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simulationSettings)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMULATION_SETTINGS(startTime = i_startTime, stopTime = i_stopTime, tolerance = i_tolerance) )
      local
        Real i_tolerance;
        Real i_stopTime;
        Real i_startTime;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("startTime=\""));
        txt = Tpl.writeStr(txt, realString(i_startTime));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" stopTime=\""));
        txt = Tpl.writeStr(txt, realString(i_stopTime));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" tolerance=\""));
        txt = Tpl.writeStr(txt, realString(i_tolerance));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end DefaultExperimentAttribute;

public function VendorAnnotations
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "<VendorAnnotations>\n",
                                    "</VendorAnnotations>"
                                }, false));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end VendorAnnotations;

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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "1");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "2");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "3");
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

protected function lm_27
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
        txt = ScalarVariable(txt, i_var, "internal", "4");
        txt = Tpl.nextIter(txt);
        txt = lm_27(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "1");
        txt = Tpl.nextIter(txt);
        txt = lm_28(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "2");
        txt = Tpl.nextIter(txt);
        txt = lm_29(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "1");
        txt = Tpl.nextIter(txt);
        txt = lm_30(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "2");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "1");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "internal", "2");
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

public function ModelVariables
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars, intAlgVars = i_vars_intAlgVars, intParamVars = i_vars_intParamVars, boolAlgVars = i_vars_boolAlgVars, boolParamVars = i_vars_boolParamVars, stringAlgVars = i_vars_stringAlgVars, stringParamVars = i_vars_stringParamVars)) )
      local
        list<SimCode.SimVar> i_vars_stringParamVars;
        list<SimCode.SimVar> i_vars_stringAlgVars;
        list<SimCode.SimVar> i_vars_boolParamVars;
        list<SimCode.SimVar> i_vars_boolAlgVars;
        list<SimCode.SimVar> i_vars_intParamVars;
        list<SimCode.SimVar> i_vars_intAlgVars;
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("<ModelVariables>\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_24(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_25(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_26(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_27(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_28(txt, i_vars_intAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_29(txt, i_vars_intParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_30(txt, i_vars_boolAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_31(txt, i_vars_boolParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_32(txt, i_vars_stringAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_33(txt, i_vars_stringParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("</ModelVariables>"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end ModelVariables;

public function ScalarVariable
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;
  input String in_i_causality;
  input String in_i_offset;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_causality, in_i_offset)
    local
      Tpl.Text txt;
      String i_causality;
      String i_offset;

    case ( txt,
           (i_simVar as SimCode.SIMVAR(type_ = i_type__, unit = i_unit, displayUnit = i_displayUnit, initialValue = i_initialValue, isFixed = i_isFixed)),
           i_causality,
           i_offset )
      local
        Boolean i_isFixed;
        Option<DAE.Exp> i_initialValue;
        String i_displayUnit;
        String i_unit;
        DAE.ExpType i_type__;
        SimCode.SimVar i_simVar;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("<ScalarVariable\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = ScalarVariableAttribute(txt, i_simVar, i_causality, i_offset);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(">\n"));
        txt = ScalarVariableType(txt, i_type__, i_unit, i_displayUnit, i_initialValue, i_isFixed);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("</ScalarVariable>"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end ScalarVariable;

protected function fun_36
  input Tpl.Text in_txt;
  input String in_i_comment;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_comment)
    local
      Tpl.Text txt;

    case ( txt,
           "" )
      then txt;

    case ( txt,
           i_comment )
      local
        String i_comment;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("description=\""));
        txt = Tpl.writeStr(txt, i_comment);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;
  end matchcontinue;
end fun_36;

public function ScalarVariableAttribute
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;
  input String in_i_causality;
  input String in_i_offset;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_causality, in_i_offset)
    local
      Tpl.Text txt;
      String i_causality;
      String i_offset;

    case ( txt,
           SimCode.SIMVAR(index = i_index, varKind = i_varKind, comment = i_comment, name = i_name),
           i_causality,
           i_offset )
      local
        DAE.ComponentRef i_name;
        String i_comment;
        BackendDAE.VarKind i_varKind;
        Integer i_index;
        Tpl.Text i_alias;
        Tpl.Text i_description;
        Tpl.Text i_variability;
        Tpl.Text i_valueReference;
      equation
        i_valueReference = Tpl.writeStr(Tpl.emptyTxt, i_offset);
        i_valueReference = Tpl.writeStr(i_valueReference, intString(i_index));
        i_variability = getVariablity(Tpl.emptyTxt, i_varKind);
        i_description = fun_36(Tpl.emptyTxt, i_comment);
        i_alias = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("noAlias"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("name=\""));
        txt = SimCodeC.crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "valueReference=\""
                                }, false));
        txt = Tpl.writeText(txt, i_valueReference);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("\"\n"));
        txt = Tpl.writeText(txt, i_description);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("variability=\""));
        txt = Tpl.writeText(txt, i_variability);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "causality=\""
                                }, false));
        txt = Tpl.writeStr(txt, i_causality);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "alias=\""
                                }, false));
        txt = Tpl.writeText(txt, i_alias);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end ScalarVariableAttribute;

public function getVariablity
  input Tpl.Text in_txt;
  input BackendDAE.VarKind in_i_varKind;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_varKind)
    local
      Tpl.Text txt;

    case ( txt,
           BackendDAE.DISCRETE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("discrete"));
      then txt;

    case ( txt,
           BackendDAE.PARAM() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("parameter"));
      then txt;

    case ( txt,
           BackendDAE.CONST() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("constant"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("continuous"));
      then txt;
  end matchcontinue;
end getVariablity;

public function ScalarVariableType
  input Tpl.Text in_txt;
  input DAE.ExpType in_i_type__;
  input String in_i_unit;
  input String in_i_displayUnit;
  input Option<DAE.Exp> in_i_initialValue;
  input Boolean in_i_isFixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_type__, in_i_unit, in_i_displayUnit, in_i_initialValue, in_i_isFixed)
    local
      Tpl.Text txt;
      String i_unit;
      String i_displayUnit;
      Option<DAE.Exp> i_initialValue;
      Boolean i_isFixed;

    case ( txt,
           DAE.ET_INT(),
           _,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<Integer/>"));
      then txt;

    case ( txt,
           DAE.ET_REAL(),
           i_unit,
           i_displayUnit,
           i_initialValue,
           i_isFixed )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<Real "));
        txt = ScalarVariableTypeCommonAttribute(txt, i_initialValue, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = ScalarVariableTypeRealAttribute(txt, i_unit, i_displayUnit);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/>"));
      then txt;

    case ( txt,
           DAE.ET_BOOL(),
           _,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<Boolean/>"));
      then txt;

    case ( txt,
           DAE.ET_STRING(),
           _,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<String/>"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _),
           _,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<Enumeration/>"));
      then txt;

    case ( txt,
           _,
           _,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKOWN_TYPE"));
      then txt;
  end matchcontinue;
end ScalarVariableType;

public function ScalarVariableTypeCommonAttribute
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_i_initialValue;
  input Boolean in_i_isFixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_initialValue, in_i_isFixed)
    local
      Tpl.Text txt;
      Boolean i_isFixed;

    case ( txt,
           SOME(i_exp),
           i_isFixed )
      local
        DAE.Exp i_exp;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("start=\""));
        txt = SimCodeC.initVal(txt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" fixed=\""));
        txt = Tpl.writeStr(txt, Tpl.booleanString(i_isFixed));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end ScalarVariableTypeCommonAttribute;

protected function fun_41
  input Tpl.Text in_txt;
  input String in_i_unit;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_unit)
    local
      Tpl.Text txt;

    case ( txt,
           "" )
      then txt;

    case ( txt,
           i_unit )
      local
        String i_unit;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("unit=\""));
        txt = Tpl.writeStr(txt, i_unit);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;
  end matchcontinue;
end fun_41;

protected function fun_42
  input Tpl.Text in_txt;
  input String in_i_displayUnit;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_displayUnit)
    local
      Tpl.Text txt;

    case ( txt,
           "" )
      then txt;

    case ( txt,
           i_displayUnit )
      local
        String i_displayUnit;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("displayUnit=\""));
        txt = Tpl.writeStr(txt, i_displayUnit);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;
  end matchcontinue;
end fun_42;

public function ScalarVariableTypeRealAttribute
  input Tpl.Text txt;
  input String i_unit;
  input String i_displayUnit;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_displayUnit__;
  Tpl.Text i_unit__;
algorithm
  i_unit__ := fun_41(Tpl.emptyTxt, i_unit);
  i_displayUnit__ := fun_42(Tpl.emptyTxt, i_displayUnit);
  out_txt := Tpl.writeText(txt, i_unit__);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" "));
  out_txt := Tpl.writeText(out_txt, i_displayUnit__);
end ScalarVariableTypeRealAttribute;

public function fmumodel_identifierFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;
  input String in_i_guid;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode, in_i_guid)
    local
      Tpl.Text txt;
      String i_guid;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(fileNamePrefix = i_fileNamePrefix, modelInfo = i_modelInfo, initialEquations = i_initialEquations)),
           i_guid )
      local
        list<SimCode.SimEqSystem> i_initialEquations;
        SimCode.ModelInfo i_modelInfo;
        String i_fileNamePrefix;
        SimCode.SimCode i_simCode;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "// define class name and unique id\n",
                                    "#define MODEL_IDENTIFIER "
                                }, false));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define MODEL_GUID \""));
        txt = Tpl.writeStr(txt, i_guid);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "\n",
                                    "// include fmu header files, typedefs and macros\n",
                                    "#include \"fmiModelFunctions.h\"\n",
                                    "\n",
                                    "// implementation of the Model Exchange functions\n",
                                    "#include \"fmu_model_interface.c\"\n",
                                    "\n"
                                }, true));
        txt = ModelDefineData(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = setStartValues(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = initializeFunction(txt, i_initialEquations);
        txt = Tpl.softNewLine(txt);
        txt = eventUpdateFunction(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fmumodel_identifierFile;

protected function lm_45
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
        txt = DefineVariables(txt, i_var, "1");
        txt = Tpl.nextIter(txt);
        txt = lm_45(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_45(txt, rest);
      then txt;
  end matchcontinue;
end lm_45;

protected function lm_46
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
        txt = DefineDerivativeVariables(txt, i_var, "2");
        txt = Tpl.nextIter(txt);
        txt = lm_46(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = DefineVariables(txt, i_var, "3");
        txt = Tpl.nextIter(txt);
        txt = lm_47(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = DefineVariables(txt, i_var, "4");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = DefineVariables(txt, i_var, "1");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = DefineVariables(txt, i_var, "2");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = DefineVariables(txt, i_var, "1");
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

protected function lm_52
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
        txt = DefineVariables(txt, i_var, "2");
        txt = Tpl.nextIter(txt);
        txt = lm_52(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = DefineVariables(txt, i_var, "1");
        txt = Tpl.nextIter(txt);
        txt = lm_53(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
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

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = DefineVariables(txt, i_var, "2");
        txt = Tpl.nextIter(txt);
        txt = lm_54(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_54(txt, rest);
      then txt;
  end matchcontinue;
end lm_54;

protected function lm_55
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
        txt = SimCodeC.crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.nextIter(txt);
        txt = lm_55(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimVar> rest;
      equation
        txt = lm_55(txt, rest);
      then txt;
  end matchcontinue;
end lm_55;

public function ModelDefineData
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_i_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_modelInfo)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.MODELINFO(varInfo = SimCode.VARINFO(numStateVars = i_varInfo_numStateVars, numAlgVars = i_varInfo_numAlgVars, numParams = i_varInfo_numParams, numIntAlgVars = i_varInfo_numIntAlgVars, numIntParams = i_varInfo_numIntParams, numStringAlgVars = i_varInfo_numStringAlgVars, numStringParamVars = i_varInfo_numStringParamVars, numBoolAlgVars = i_varInfo_numBoolAlgVars, numBoolParams = i_varInfo_numBoolParams, numZeroCrossings = i_varInfo_numZeroCrossings), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars, intAlgVars = i_vars_intAlgVars, intParamVars = i_vars_intParamVars, boolAlgVars = i_vars_boolAlgVars, boolParamVars = i_vars_boolParamVars, stringAlgVars = i_vars_stringAlgVars, stringParamVars = i_vars_stringParamVars)) )
      local
        list<SimCode.SimVar> i_vars_stringParamVars;
        list<SimCode.SimVar> i_vars_stringAlgVars;
        list<SimCode.SimVar> i_vars_boolParamVars;
        list<SimCode.SimVar> i_vars_boolAlgVars;
        list<SimCode.SimVar> i_vars_intParamVars;
        list<SimCode.SimVar> i_vars_intAlgVars;
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
        Integer i_varInfo_numZeroCrossings;
        Integer i_varInfo_numBoolParams;
        Integer i_varInfo_numBoolAlgVars;
        Integer i_varInfo_numStringParamVars;
        Integer i_varInfo_numStringAlgVars;
        Integer i_varInfo_numIntParams;
        Integer i_varInfo_numIntAlgVars;
        Integer i_varInfo_numParams;
        Integer i_varInfo_numAlgVars;
        Integer i_varInfo_numStateVars;
        Integer ret_8;
        Tpl.Text i_numberOfBooleans;
        Integer ret_6;
        Tpl.Text i_numberOfStrings;
        Integer ret_4;
        Tpl.Text i_numberOfIntegers;
        Integer ret_2;
        Integer ret_1;
        Tpl.Text i_numberOfReals;
      equation
        ret_1 = intAdd(i_varInfo_numAlgVars, i_varInfo_numParams);
        ret_2 = intAdd(i_varInfo_numStateVars, ret_1);
        i_numberOfReals = Tpl.writeStr(Tpl.emptyTxt, intString(ret_2));
        ret_4 = intAdd(i_varInfo_numIntAlgVars, i_varInfo_numIntParams);
        i_numberOfIntegers = Tpl.writeStr(Tpl.emptyTxt, intString(ret_4));
        ret_6 = intAdd(i_varInfo_numStringAlgVars, i_varInfo_numStringParamVars);
        i_numberOfStrings = Tpl.writeStr(Tpl.emptyTxt, intString(ret_6));
        ret_8 = intAdd(i_varInfo_numBoolAlgVars, i_varInfo_numBoolParams);
        i_numberOfBooleans = Tpl.writeStr(Tpl.emptyTxt, intString(ret_8));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "// define model size\n",
                                    "#define NUMBER_OF_STATES "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStateVars));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NUMBER_OF_EVENT_INDICATORS "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numZeroCrossings));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NUMBER_OF_REALS "));
        txt = Tpl.writeText(txt, i_numberOfReals);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NUMBER_OF_INTEGERS "));
        txt = Tpl.writeText(txt, i_numberOfIntegers);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NUMBER_OF_STRINGS "));
        txt = Tpl.writeText(txt, i_numberOfStrings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NUMBER_OF_BOOLEANS "));
        txt = Tpl.writeText(txt, i_numberOfBooleans);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "// define variable data for model\n"
                                }, true));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_45(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_46(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_47(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_48(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_49(txt, i_vars_intAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_50(txt, i_vars_intParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_51(txt, i_vars_boolAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_52(txt, i_vars_boolParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_53(txt, i_vars_stringAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_54(txt, i_vars_stringParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "// define initial state vector as vector of value references\n",
                                    "#define STATES { "
                                }, false));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_55(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " }\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end ModelDefineData;

public function DefineDerivativeVariables
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_prefix)
    local
      Tpl.Text txt;
      String i_prefix;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index),
           i_prefix )
      local
        Integer i_index;
        DAE.ComponentRef i_name;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = dervativeNameCStyle(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeStr(txt, i_prefix);
        txt = Tpl.writeStr(txt, intString(i_index));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end DefineDerivativeVariables;

public function dervativeNameCStyle
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_QUAL(ident = "$DER", componentRef = i_componentRef) )
      local
        DAE.ComponentRef i_componentRef;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("der_"));
        txt = SimCodeC.crefStr(txt, i_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end dervativeNameCStyle;

protected function fun_59
  input Tpl.Text in_txt;
  input String in_i_comment;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_comment)
    local
      Tpl.Text txt;

    case ( txt,
           "" )
      then txt;

    case ( txt,
           i_comment )
      local
        String i_comment;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("// \""));
        txt = Tpl.writeStr(txt, i_comment);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;
  end matchcontinue;
end fun_59;

public function DefineVariables
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;
  input String in_i_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_prefix)
    local
      Tpl.Text txt;
      String i_prefix;

    case ( txt,
           SimCode.SIMVAR(comment = i_comment, name = i_name, index = i_index),
           i_prefix )
      local
        Integer i_index;
        DAE.ComponentRef i_name;
        String i_comment;
        Tpl.Text i_description;
      equation
        i_description = fun_59(Tpl.emptyTxt, i_comment);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = SimCodeC.crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ "));
        txt = Tpl.writeStr(txt, i_prefix);
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, i_description);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end DefineVariables;

public function setStartValues
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "// Set values for all variables that define a start value\n",
                                    "void setStartValues(ModelInstance *comp) {\n",
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end setStartValues;

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
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           i_varDecls )
      local
        list<SimCode.SimEqSystem> rest;
        SimCode.SimEqSystem i_eq;
      equation
        (txt, i_varDecls) = SimCodeC.equation_(txt, i_eq, SimCode.contextOther, i_varDecls);
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
        DAE.ComponentRef i_cref;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (sim_verbose) { printf(\"Setting variable start value: %s(start=%f)\\n\", \""));
        txt = SimCodeC.cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\", "));
        txt = SimCodeC.cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("); }"));
        txt = Tpl.nextIter(txt);
        txt = lm_63(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<SimCode.SimEqSystem> rest;
      equation
        txt = lm_63(txt, rest);
      then txt;
  end matchcontinue;
end lm_63;

public function initializeFunction
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> i_initialEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_eqPart;
  Tpl.Text i_varDecls;
algorithm
  i_varDecls := Tpl.emptyTxt;
  i_eqPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (i_eqPart, i_varDecls) := lm_62(i_eqPart, i_initialEquations, i_varDecls);
  i_eqPart := Tpl.popIter(i_eqPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "// Used to set the first time event, if any.\n",
                                   "void initialize(ModelInstance* comp, fmiEventInfo* eventInfo) {\n",
                                   "{\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, i_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(out_txt, i_eqPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_63(out_txt, i_initialEquations);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end initializeFunction;

public function eventUpdateFunction
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "// Used to set the next time event, if any.\n",
                                    "void eventUpdate(ModelInstance* comp, fmiEventInfo* eventInfo) {\n",
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end eventUpdateFunction;

protected function fun_66
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
end fun_66;

protected function lm_67
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
        txt = lm_67(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_67(txt, rest);
      then txt;
  end matchcontinue;
end lm_67;

protected function fun_68
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
end fun_68;

protected function fun_69
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
end fun_69;

public function fmuMakefile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(directory = i_modelInfo_directory), makefileParams = SimCode.MAKEFILE_PARAMS(libs = i_makefileParams_libs, ccompiler = i_makefileParams_ccompiler, cxxcompiler = i_makefileParams_cxxcompiler, linker = i_makefileParams_linker, exeext = i_makefileParams_exeext, dllext = i_makefileParams_dllext, omhome = i_makefileParams_omhome, cflags = i_makefileParams_cflags, ldflags = i_makefileParams_ldflags, senddatalibs = i_makefileParams_senddatalibs), fileNamePrefix = i_fileNamePrefix) )
      local
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
        String str_5;
        Tpl.Text i_libsPos2;
        String str_3;
        Tpl.Text i_libsPos1;
        Tpl.Text i_libsStr;
        Tpl.Text i_dirExtra;
      equation
        i_dirExtra = fun_66(Tpl.emptyTxt, i_modelInfo_directory);
        i_libsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_libsStr = lm_67(i_libsStr, i_makefileParams_libs);
        i_libsStr = Tpl.popIter(i_libsStr);
        str_3 = Tpl.textString(i_dirExtra);
        i_libsPos1 = fun_68(Tpl.emptyTxt, str_3, i_libsStr);
        str_5 = Tpl.textString(i_dirExtra);
        i_libsPos2 = fun_69(Tpl.emptyTxt, str_5, i_libsStr);
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
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(".cpp\n"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\t"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(CXX) $(CFLAGS) -I. -o "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$(DLLEXT) "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
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
end fmuMakefile;

end SimCodeFMU;