package SimCodeFMU

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
public import Settings;

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
        Tpl.Text txt_4;
        Tpl.Text txt_3;
        Tpl.Text txt_2;
        Tpl.Text txt_1;
        Tpl.Text txt_0;
      equation
        txt_0 = fmuModelDescriptionFile(emptyTxt, i_simCode);
        Tpl.textFile(txt_0, "modelDescription.xml");
        txt_1 = fmumodel_identifierFile(emptyTxt, i_simCode);
        txt_2 = Tpl.writeStr(emptyTxt, i_fileNamePrefix);
        txt_2 = Tpl.writeTok(txt_2, Tpl.ST_STRING("_FMU.cpp"));
        Tpl.textFile(txt_1, Tpl.textString(txt_2));
        txt_3 = fmuMakefile(emptyTxt, i_simCode);
        txt_4 = Tpl.writeStr(emptyTxt, i_fileNamePrefix);
        txt_4 = Tpl.writeTok(txt_4, Tpl.ST_STRING("_FMU.makefile"));
        Tpl.textFile(txt_3, Tpl.textString(txt_4));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateModel;

public function fmuModelDescriptionFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = _)) )
      local
        SimCode.SimCode i_simCode;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("<?xml version=\"1.0\" encoding=\"UTF8\"?>\n"));
        txt = fmiModelDescription(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fmuModelDescriptionFile;

public function fmiModelDescription
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = i_modelInfo)) )
      local
        SimCode.ModelInfo i_modelInfo;
        SimCode.SimCode i_simCode;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("<fmiModelDescription "));
        txt = fmiModelDescriptionAttributes(txt, i_simCode);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(">\n"));
        txt = UnitDefinitions(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = TypeDefinitions(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = DefaultExperiment(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = VendorAnnotations(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = ModelVariables(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("</fmiModelDescription>"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fmiModelDescription;

public function fmiModelDescriptionAttributes
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(name = i_modelInfo_name), fileNamePrefix = i_fileNamePrefix) )
      local
        String i_fileNamePrefix;
        Absyn.Path i_modelInfo_name;
        Tpl.Text i_numberOfEventIndicators;
        Tpl.Text i_numberOfContinuousStates;
        Tpl.Text i_variableNamingConvention;
        Tpl.Text i_generationDateAndTime;
        String ret_8;
        Tpl.Text i_generationTool;
        Tpl.Text i_version;
        Tpl.Text i_author;
        Tpl.Text i_description;
        Tpl.Text i_guid;
        Tpl.Text i_modelIdentifier;
        Tpl.Text i_modelName;
        Tpl.Text i_fmiVersion;
      equation
        i_fmiVersion = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("1.0"));
        i_modelName = dotPath(emptyTxt, i_modelInfo_name);
        i_modelIdentifier = Tpl.writeStr(emptyTxt, i_fileNamePrefix);
        i_guid = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("0.0"));
        i_description = emptyTxt;
        i_author = emptyTxt;
        i_version = emptyTxt;
        i_generationTool = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("OpenModelica Compiler "));
        ret_8 = Settings.getVersionNr();
        i_generationTool = Tpl.writeStr(i_generationTool, ret_8);
        i_generationDateAndTime = emptyTxt;
        i_variableNamingConvention = Tpl.writeTok(emptyTxt, Tpl.ST_STRING("structured"));
        i_numberOfContinuousStates = emptyTxt;
        i_numberOfEventIndicators = emptyTxt;
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fmiVersion=\""));
        txt = Tpl.writeText(txt, i_fmiVersion);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" modelName=\""));
        txt = Tpl.writeText(txt, i_modelName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" modelIdentifier=\""));
        txt = Tpl.writeText(txt, i_modelIdentifier);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" guid=\"{"));
        txt = Tpl.writeText(txt, i_guid);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}\" description=\""));
        txt = Tpl.writeText(txt, i_description);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "author=\""
                                }, false));
        txt = Tpl.writeText(txt, i_author);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" version=\""));
        txt = Tpl.writeText(txt, i_version);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "generationTool=\""
                                }, false));
        txt = Tpl.writeText(txt, i_generationTool);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" generationDateAndTime=\""));
        txt = Tpl.writeText(txt, i_generationDateAndTime);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "variableNamingConvention=\""
                                }, false));
        txt = Tpl.writeText(txt, i_variableNamingConvention);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" numberOfContinuousStates=\""));
        txt = Tpl.writeText(txt, i_numberOfContinuousStates);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" numberOfEventIndicators=\""));
        txt = Tpl.writeText(txt, i_numberOfEventIndicators);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fmiModelDescriptionAttributes;

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
                                    "<DefaultExperiment>\n",
                                    "</DefaultExperiment>"
                                }, false));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end DefaultExperiment;

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
        txt = ScalarVariable(txt, i_var, "continuous");
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
        txt = ScalarVariable(txt, i_var, "continuous");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "continuous");
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
           i_var :: rest )
      local
        list<SimCode.SimVar> rest;
        SimCode.SimVar i_var;
      equation
        txt = ScalarVariable(txt, i_var, "parameter");
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
        txt = ScalarVariable(txt, i_var, "continuous");
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
        txt = ScalarVariable(txt, i_var, "continuous");
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
        txt = ScalarVariable(txt, i_var, "parameter");
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
        txt = ScalarVariable(txt, i_var, "continuous");
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
        txt = ScalarVariable(txt, i_var, "parameter");
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
        txt = ScalarVariable(txt, i_var, "continuous");
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
        txt = ScalarVariable(txt, i_var, "parameter");
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
           SimCode.MODELINFO(varInfo = SimCode.VARINFO(numHelpVars = _), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars, extObjVars = i_vars_extObjVars, intAlgVars = i_vars_intAlgVars, intParamVars = i_vars_intParamVars, boolAlgVars = i_vars_boolAlgVars, boolParamVars = i_vars_boolParamVars, stringAlgVars = i_vars_stringAlgVars, stringParamVars = i_vars_stringParamVars)) )
      local
        list<SimCode.SimVar> i_vars_stringParamVars;
        list<SimCode.SimVar> i_vars_stringAlgVars;
        list<SimCode.SimVar> i_vars_boolParamVars;
        list<SimCode.SimVar> i_vars_boolAlgVars;
        list<SimCode.SimVar> i_vars_intParamVars;
        list<SimCode.SimVar> i_vars_intAlgVars;
        list<SimCode.SimVar> i_vars_extObjVars;
        list<SimCode.SimVar> i_vars_paramVars;
        list<SimCode.SimVar> i_vars_algVars;
        list<SimCode.SimVar> i_vars_derivativeVars;
        list<SimCode.SimVar> i_vars_stateVars;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("<ModelVariables>\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_21(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_22(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_23(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_24(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_25(txt, i_vars_extObjVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_26(txt, i_vars_intAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_27(txt, i_vars_intParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_28(txt, i_vars_boolAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_29(txt, i_vars_boolParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_30(txt, i_vars_stringAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_31(txt, i_vars_stringParamVars);
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
  input String in_i_variability;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_variability)
    local
      Tpl.Text txt;
      String i_variability;

    case ( txt,
           (i_simVar as SimCode.SIMVAR(name = _)),
           i_variability )
      local
        SimCode.SimVar i_simVar;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("<ScalarVariable >\n"));
        txt = ScalarVariableAttribute(txt, i_simVar, i_variability);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("</ScalarVariable>"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end ScalarVariable;

public function ScalarVariableAttribute
  input Tpl.Text in_txt;
  input SimCode.SimVar in_i_simVar;
  input String in_i_variability;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simVar, in_i_variability)
    local
      Tpl.Text txt;
      String i_variability;

    case ( txt,
           SimCode.SIMVAR(comment = i_comment, name = i_name),
           i_variability )
      local
        DAE.ComponentRef i_name;
        String i_comment;
        Tpl.Text i_alias;
        Tpl.Text i_causality;
        Tpl.Text i_description;
        Tpl.Text i_valueReference;
      equation
        i_valueReference = emptyTxt;
        i_description = Tpl.writeStr(emptyTxt, i_comment);
        i_causality = emptyTxt;
        i_alias = emptyTxt;
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("name=\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" valueReference=\""));
        txt = Tpl.writeText(txt, i_valueReference);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" description=\""));
        txt = Tpl.writeText(txt, i_description);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\"\n",
                                    "variability=\""
                                }, false));
        txt = Tpl.writeStr(txt, i_variability);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" causality=\""));
        txt = Tpl.writeText(txt, i_causality);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\" alias=\""));
        txt = Tpl.writeText(txt, i_alias);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end ScalarVariableAttribute;

public function crefStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_i_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_cr)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      local
        list<DAE.Subscript> i_subscriptLst;
        DAE.Ident i_ident;
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsStr(txt, i_subscriptLst);
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

protected function lm_36
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
        txt = subscriptStr(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_36(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<DAE.Subscript> rest;
      equation
        txt = lm_36(txt, rest);
      then txt;
  end matchcontinue;
end lm_36;

public function subscriptsStr
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
        txt = lm_36(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;
  end matchcontinue;
end subscriptsStr;

protected function fun_38
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
end fun_38;

public function subscriptStr
  input Tpl.Text txt;
  input DAE.Subscript i_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text i_varDecls;
  Tpl.Text i_preExp;
algorithm
  i_preExp := emptyTxt;
  i_varDecls := emptyTxt;
  (out_txt, i_varDecls, i_preExp) := fun_38(txt, i_subscript, i_varDecls, i_preExp);
end subscriptStr;

protected function fun_40
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
end fun_40;

protected function fun_41
  input Tpl.Text in_txt;
  input DAE.Exp in_i_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_exp)
    local
      Tpl.Text txt;

    case ( txt,
           (i_e as DAE.ICONST(integer = i_integer)) )
      local
        Integer i_integer;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then txt;

    case ( txt,
           (i_e as DAE.RCONST(real = i_real)) )
      local
        Real i_real;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, realString(i_real));
      then txt;

    case ( txt,
           (i_e as DAE.BCONST(bool = i_bool)) )
      local
        Boolean i_bool;
        DAE.Exp i_e;
      equation
        txt = fun_40(txt, i_bool);
      then txt;

    case ( txt,
           (i_e as DAE.ENUM_LITERAL(index = i_index)) )
      local
        Integer i_index;
        DAE.Exp i_e;
      equation
        txt = Tpl.writeStr(txt, intString(i_index));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_EXP"));
      then txt;
  end matchcontinue;
end fun_41;

public function daeExp
  input Tpl.Text txt;
  input DAE.Exp i_exp;
  input SimCode.Context i_context;
  input Tpl.Text i_preExp;
  input Tpl.Text i_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_i_preExp;
  output Tpl.Text out_i_varDecls;
algorithm
  out_txt := fun_41(txt, i_exp);
  out_i_preExp := i_preExp;
  out_i_varDecls := i_varDecls;
end daeExp;

public function fmumodel_identifierFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_i_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_i_simCode)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.SIMCODE(fileNamePrefix = i_fileNamePrefix) )
      local
        String i_fileNamePrefix;
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define MODEL_IDENTIFIER "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#define MODEL_GUID\n",
                                    "#include \"fmiModelFunctions.h\"\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fmumodel_identifierFile;

protected function fun_44
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
end fun_44;

protected function lm_45
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
        txt = lm_45(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      local
        list<String> rest;
      equation
        txt = lm_45(txt, rest);
      then txt;
  end matchcontinue;
end lm_45;

protected function fun_46
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
end fun_46;

protected function fun_47
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
end fun_47;

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
        i_dirExtra = fun_44(emptyTxt, i_modelInfo_directory);
        i_libsStr = Tpl.pushIter(emptyTxt, Tpl.ITER_OPTIONS(0, NONE, SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        i_libsStr = lm_45(i_libsStr, i_makefileParams_libs);
        i_libsStr = Tpl.popIter(i_libsStr);
        str_3 = Tpl.textString(i_dirExtra);
        i_libsPos1 = fun_46(emptyTxt, str_3, i_libsStr);
        str_5 = Tpl.textString(i_dirExtra);
        i_libsPos2 = fun_47(emptyTxt, str_5, i_libsStr);
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