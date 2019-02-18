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

encapsulated package SerializeInitXML

import SimCode;
import SimCode.ModelInfo;
import SimCode.SimCode.SIMCODE;
import File;

protected
import BackendDAE.VarKind;
import CR=ComponentReference;
import CodegenUtil;
import DAE.{Exp,Type};
import Dump;
import ExpressionDump.printExpStr;
import File.Escape.XML;
import Settings;
import SimCode.{SimulationSettings,VarInfo};
import SimCodeVar.{AliasVariable,Causality,SimVar};
import SimCodeUtil;
import Tpl;
import Types;
import Util;

public

function simulationInitFile
 "Generates the contents of the init.xml file for the simulation case."
  input SimCode.SimCode simCode;
  input String guid;
algorithm
  true := simulationInitFileReturnBool(simCode, guid);
end simulationInitFile;

function simulationInitFileReturnBool
 "Generates the contents of the init.xml file for the simulation case."
  input SimCode.SimCode simCode;
  input String guid;
  output Boolean success = false;
protected
  SimCodeFunction.MakefileParams makefileParams;
  ModelInfo modelInfo;
  VarInfo vi;
  SimulationSettings s;
  File.File file = File.File();
  String FMUType;
algorithm
  try
  _ := match Config.simCodeTarget()
    case "omsic" algorithm
      File.open(file, simCode.fullPathPrefix+"/"+simCode.fileNamePrefix + "_init.xml", File.Mode.Write);
      then();
    else algorithm
      File.open(file, simCode.fileNamePrefix + "_init.xml", File.Mode.Write);
      then();
  end match;
  makefileParams := simCode.makefileParams;
  modelInfo := simCode.modelInfo;
  vi := modelInfo.varInfo;
  SOME(s) := simCode.simulationSettingsOpt;
  FMUType := match Config.simCodeTarget()
    case "omsic" then "2.0";
    case "omsicpp" then "2.0";
    else "1.0";
  end match;


  File.write(file, "<?xml version = \"1.0\" encoding=\"UTF-8\"?>\n\n");
  File.write(file, "<!-- description of the model interface using an extention of the FMI standard -->\n");
  File.write(file, "<fmiModelDescription\n");
  File.write(file, "  fmiVersion                          = \""+FMUType+"\"\n\n");

  File.write(file, "  modelName                           = \"");
  Dump.writePath(file, modelInfo.name, initialDot=false);
  File.write(file, "\"\n");

  File.write(file, "  modelIdentifier                     = \"");
  Dump.writePath(file, modelInfo.name, delimiter="_", initialDot=false);
  File.write(file, "\"\n\n");

  File.write(file, "  OPENMODELICAHOME                    = \"");
  File.write(file, makefileParams.omhome);
  File.write(file, "\"\n\n");


  File.write(file, "  guid                                = \"{");
  File.write(file, guid);
  File.write(file, "}\"\n\n");


  File.write(file, "  description                         = \"");
  File.writeEscape(file, modelInfo.description, XML);
  File.write(file, "\"\n");

  File.write(file, "  generationTool                      = \"OpenModelica Compiler ");
  File.write(file, Settings.getVersionNr());
  File.write(file, "\"\n");

  File.write(file, "  generationDateAndTime               = \"");
  xsdateTime(file, Util.getCurrentDateTime());
  File.write(file, "\"\n\n");


  File.write(file, "  variableNamingConvention            = \"structured\"\n\n");

  File.write(file, "  numberOfEventIndicators             = \"");
  File.writeInt(file, vi.numZeroCrossings);
  File.write(file, "\"  cmt_numberOfEventIndicators             = \"NG:       number of zero crossings,                           FMI\"\n");

  File.write(file, "  numberOfTimeEvents                  = \"");
  File.writeInt(file, vi.numTimeEvents);
  File.write(file, "\"  cmt_numberOfTimeEvents                  = \"NG_SAM:   number of zero crossings that are samples,          OMC\"\n\n");


  File.write(file, "  numberOfInputVariables              = \"");
  File.writeInt(file, vi.numInVars);
  File.write(file, "\"  cmt_numberOfInputVariables              = \"NI:       number of inputvar on topmodel,                     OMC\"\n");

  File.write(file, "  numberOfOutputVariables             = \"");
  File.writeInt(file, vi.numOutVars);
  File.write(file, "\"  cmt_numberOfOutputVariables             = \"NO:       number of outputvar on topmodel,                    OMC\"\n\n");

  File.write(file, "  numberOfExternalObjects             = \"");
  File.writeInt(file, vi.numExternalObjects);

  File.write(file, "\"  cmt_numberOfExternalObjects             = \"NEXT:     number of external objects,                         OMC\"\n");

  File.write(file, "  numberOfFunctions                   = \"");
  File.writeInt(file, listLength(modelInfo.functions));
  File.write(file, "\"  cmt_numberOfFunctions                   = \"NFUNC:    number of functions used by the simulation,         OMC\"\n\n");


  File.write(file, "  numberOfContinuousStates            = \"");
  File.writeInt(file, vi.numStateVars);
  File.write(file, "\"  cmt_numberOfContinuousStates            = \"NX:       number of states,                                   FMI\"\n");

  File.write(file, "  numberOfRealAlgebraicVariables      = \"");
  File.writeInt(file, vi.numAlgVars+vi.numDiscreteReal+vi.numOptimizeConstraints+vi.numOptimizeFinalConstraints);
  File.write(file, "\"  cmt_numberOfRealAlgebraicVariables      = \"NY:       number of real variables,                           OMC\"\n");

  File.write(file, "  numberOfRealAlgebraicAliasVariables = \"");
  File.writeInt(file, vi.numAlgAliasVars);
  File.write(file, "\"  cmt_numberOfRealAlgebraicAliasVariables = \"NA:       number of alias variables,                          OMC\"\n");

  File.write(file, "  numberOfRealParameters              = \"");
  File.writeInt(file, vi.numParams);
  File.write(file, "\"  cmt_numberOfRealParameters              = \"NP:       number of parameters,                               OMC\"\n\n");


  File.write(file, "  numberOfIntegerAlgebraicVariables   = \"");
  File.writeInt(file, vi.numIntAlgVars);
  File.write(file, "\"  cmt_numberOfIntegerAlgebraicVariables   = \"NYINT:    number of alg. int variables,                       OMC\"\n");

  File.write(file, "  numberOfIntegerAliasVariables       = \"");
  File.writeInt(file, vi.numIntAliasVars);
  File.write(file, "\"  cmt_numberOfIntegerAliasVariables       = \"NAINT:    number of alias int variables,                      OMC\"\n");

  File.write(file, "  numberOfIntegerParameters           = \"");
  File.writeInt(file, vi.numIntParams);
  File.write(file, "\"  cmt_numberOfIntegerParameters           = \"NPINT:    number of int parameters,                           OMC\"\n\n");

  File.write(file, "  numberOfStringAlgebraicVariables    = \"");
  File.writeInt(file, vi.numStringAlgVars);
  File.write(file, "\"  cmt_numberOfStringAlgebraicVariables    = \"NYSTR:    number of alg. string variables,                    OMC\"\n");

  File.write(file, "  numberOfStringAliasVariables        = \"");
  File.writeInt(file, vi.numStringAliasVars);
  File.write(file, "\"  cmt_numberOfStringAliasVariables        = \"NASTR:    number of alias string variables,                   OMC\"\n");

  File.write(file, "  numberOfStringParameters            = \"");
  File.writeInt(file, vi.numStringParamVars);
  File.write(file, "\"  cmt_numberOfStringParameters            = \"NPSTR:    number of string parameters,                        OMC\"\n\n");


  File.write(file, "  numberOfBooleanAlgebraicVariables   = \"");
  File.writeInt(file, vi.numBoolAlgVars);
  File.write(file, "\"  cmt_numberOfBooleanAlgebraicVariables   = \"NYBOOL:   number of alg. bool variables,                      OMC\"\n");

  File.write(file, "  numberOfBooleanAliasVariables       = \"");
  File.writeInt(file, vi.numBoolAliasVars);
  File.write(file, "\"  cmt_numberOfBooleanAliasVariables       = \"NABOOL:   number of alias bool variables,                     OMC\"\n");

  File.write(file, "  numberOfBooleanParameters           = \"");
  File.writeInt(file, vi.numBoolParams);
  File.write(file, "\"  cmt_numberOfBooleanParameters           = \"NPBOOL:   number of bool parameters,                          OMC\" >\n\n\n");


  File.write(file, "  <!-- startTime, stopTime, tolerance are FMI specific, all others are OMC specific -->\n");

  File.write(file, "  <DefaultExperiment\n");

  File.write(file, "    startTime      = \"");
  File.writeReal(file, s.startTime);
  File.write(file, "\"\n");

  File.write(file, "    stopTime       = \"");
  File.writeReal(file, s.stopTime);
  File.write(file, "\"\n");

  File.write(file, "    stepSize       = \"");
  File.writeReal(file, s.stepSize);
  File.write(file, "\"\n");

  File.write(file, "    tolerance      = \"");
  File.writeReal(file, s.tolerance);
  File.write(file, "\"\n");

  File.write(file, "    solver        = \"");
  File.write(file, s.method);
  File.write(file, "\"\n");

  File.write(file, "    outputFormat      = \"");
  File.write(file, s.outputFormat);
  File.write(file, "\"\n");

  File.write(file, "    variableFilter      = \"");
  File.write(file, s.variableFilter);
  File.write(file, "\" />\n\n");

  File.write(file, "  <!-- variables in the model -->\n");
  File.write(file, "  <ModelVariables>\n\n");
  modelVariables(file, modelInfo);
  File.write(file, "\n\n\n  </ModelVariables>\n\n");

  File.write(file, "\n</fmiModelDescription>\n\n");
  success := true;
  else
  end try;
end simulationInitFileReturnBool;

protected

function modelVariables "Generates code for ModelVariables file for FMU target."
  input File.File file;
  input ModelInfo modelInfo;
protected
  SimCodeVar.SimVars vars;
  Integer vr, ix=0;
algorithm

  // set starting index
  vr := match Config.simCodeTarget()
    case "omsic" then 0;
    case "omsicpp" then 0;
    else 1000;
  end match;

  vars := modelInfo.vars;

  vr := scalarVariables(file, vars.stateVars, "rSta", vr);
  vr := scalarVariables(file, vars.derivativeVars, "rDer", vr);
  (vr,ix) := scalarVariables(file, vars.algVars, "rAlg", vr, ix);
  (vr,ix) := scalarVariables(file, vars.discreteAlgVars, "rAlg", vr, ix);
  (vr,ix) := scalarVariables(file, vars.realOptimizeConstraintsVars, "rAlg", vr, ix);
  (vr,ix) := scalarVariables(file, vars.realOptimizeFinalConstraintsVars, "rAlg", vr, ix);
  vr := scalarVariables(file, vars.paramVars, "rPar", vr);
  vr := scalarVariables(file, vars.aliasVars, "rAli", vr);

  vr := scalarVariables(file, vars.intAlgVars, "iAlg", vr);
  vr := scalarVariables(file, vars.intParamVars, "iPar", vr);
  vr := scalarVariables(file, vars.intAliasVars, "iAli", vr);

  vr := scalarVariables(file, vars.boolAlgVars, "bAlg", vr);
  vr := scalarVariables(file, vars.boolParamVars, "bPar", vr);
  vr := scalarVariables(file, vars.boolAliasVars, "bAli", vr);

  vr := scalarVariables(file, vars.stringAlgVars, "sAlg", vr);
  vr := scalarVariables(file, vars.stringParamVars, "sPar", vr);
  vr := scalarVariables(file, vars.stringAliasVars, "sAli", vr);

  // sensitivity variables
  vr := scalarVariables(file, vars.sensitivityVars, "rSen", vr);


end modelVariables;

function scalarVariables
  input File.File file;
  input list<SimVar> vars;
  input String classType;
  input output Integer valueReference;
  input output Integer index=0;
algorithm
  for var in vars loop
    scalarVariable(file, var, classType, valueReference, index);
    index := index + 1;
    valueReference := valueReference + 1;
  end for;
end scalarVariables;

function scalarVariable
  input File.File file;
  input SimVar var;
  input String classType;
  input Integer valueReference;
  input Integer classIndex;
algorithm
  File.write(file, "  <ScalarVariable\n");
  scalarVariableAttribute(file, var, classType, valueReference, classIndex);
  File.write(file, "    ");
  // TODO: Convert ScalarVariableType to File.mo?
  File.write(file, Tpl.textString(CodegenUtil.ScalarVariableType(Tpl.emptyTxt, var.unit, var.displayUnit, var.minValue, var.maxValue, var.initialValue, var.nominalValue, var.isFixed, var.type_)));
  File.write(file, "\n  </ScalarVariable>\n");
end scalarVariable;

function scalarVariableAttribute "Generates code for ScalarVariable Attribute file for FMU target."
  input File.File file;
  input SimVar simVar;
  input String classType;
  input Integer valueReference;
  input Integer classIndex;
protected
  Integer inputIndex = SimCodeUtil.getInputIndex(simVar);
  DAE.ElementSource source;
  SourceInfo info;
algorithm
  source := simVar.source;
  info := source.info;

  File.write(file, "    name = \"");
  CR.writeCref(file, simVar.name, XML);
  File.write(file, "\"\n");

  File.write(file, "    valueReference = \"");
  File.writeInt(file, valueReference);
  File.write(file, "\"\n");

  if simVar.comment <> "" then
    File.write(file, "    description = \"");
    File.writeEscape(file, simVar.comment, XML);
    File.write(file, "\"\n");
  end if;

  File.write(file, "    variability = \"");
  File.write(file, getVariablity(simVar.varKind));
  File.write(file, "\" isDiscrete = \"");
  File.write(file, String(simVar.isDiscrete));
  File.write(file, "\"\n");

  File.write(file, "    causality = \"");
  File.write(file, getCausality(simVar.causality));
  File.write(file, "\" isValueChangeable = \"");
  File.write(file, String(simVar.isValueChangeable));
  File.write(file, "\"\n");

  if inputIndex <> -1 then
    File.write(file, "    inputIndex = \"");
    File.writeInt(file, inputIndex);
    File.write(file, "\"\n");
  end if;

  File.write(file, "    alias = ");
  getAliasVar(file, simVar);
  File.write(file, "\n");

  File.write(file, "    classIndex = \"");
  File.writeInt(file, classIndex);
  File.write(file, "\" classType = \"");
  File.write(file, classType);
  File.write(file, "\"\n");

  File.write(file, "    isProtected = \"");
  File.write(file, String(simVar.isProtected));
  File.write(file, "\" hideResult = \"");
  File.write(file, String(simVar.hideResult));
  File.write(file, "\"\n");

  File.write(file, "    fileName = \"");
  File.writeEscape(file, info.fileName, XML);
  File.write(file, "\" startLine = \"");
  File.writeInt(file, info.lineNumberStart);
  File.write(file, "\" startColumn = \"");
  File.writeInt(file, info.columnNumberStart);
  File.write(file, "\" endLine = \"");
  File.writeInt(file, info.lineNumberEnd);
  File.write(file, "\" endColumn = \"");
  File.writeInt(file, info.columnNumberEnd);
  File.write(file, "\" fileWritable = \"");
  File.write(file, String(not info.isReadOnly));
  File.write(file, "\">\n");
end scalarVariableAttribute;

function scalarVariableType "Generates code for ScalarVariable Type file for FMU target."
  input File.File file;
  input String unit, displayUnit;
  input Option<Exp> minValue, maxValue, startValue, nominalValue;
  input Boolean isFixed;
  input Type t;
protected
  Absyn.Path path;
algorithm
  _ := match t
  case Type.T_INTEGER(__)
    algorithm
      File.write(file, "<Integer ");
      scalarVariableTypeAttribute(file, startValue, "start");
      scalarVariableTypeFixedAttribute(file, isFixed);
      scalarVariableTypeAttribute(file, minValue, "min");
      scalarVariableTypeAttribute(file, maxValue, "max");
      scalarVariableTypeStringAttribute(file, unit, "unit");
      scalarVariableTypeStringAttribute(file, displayUnit, "displayUnit");
      File.write(file, " />");
    then ();
  case Type.T_REAL(__)
    algorithm
      File.write(file, "<Real ");
      scalarVariableTypeAttribute(file, startValue, "start");
      scalarVariableTypeFixedAttribute(file, isFixed);
      scalarVariableTypeUseAttribute(file, nominalValue, "useNominal", "nominal");
      scalarVariableTypeAttribute(file, minValue, "min");
      scalarVariableTypeAttribute(file, maxValue, "max");
      scalarVariableTypeStringAttribute(file, unit, "unit");
      scalarVariableTypeStringAttribute(file, displayUnit, "displayUnit");
    then ();
  case Type.T_BOOL(__)
    algorithm
      File.write(file, "<Boolean ");
      scalarVariableTypeAttribute(file, startValue, "start");
      scalarVariableTypeFixedAttribute(file, isFixed);
      scalarVariableTypeStringAttribute(file, unit, "unit");
      scalarVariableTypeStringAttribute(file, displayUnit, "displayUnit");
    then ();
  case Type.T_STRING(__)
    algorithm
      File.write(file, "<String ");
      scalarVariableTypeAttribute(file, startValue, "start");
      scalarVariableTypeFixedAttribute(file, isFixed);
      scalarVariableTypeStringAttribute(file, unit, "unit");
      scalarVariableTypeStringAttribute(file, displayUnit, "displayUnit");
    then ();
  case Type.T_ENUMERATION(__)
    algorithm
      File.write(file, "<Integer ");
      scalarVariableTypeAttribute(file, startValue, "start");
      scalarVariableTypeFixedAttribute(file, isFixed);
      scalarVariableTypeStringAttribute(file, unit, "unit");
      scalarVariableTypeStringAttribute(file, displayUnit, "displayUnit");
    then ();
  case Type.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=path))
    algorithm
      File.write(file, "<ExternalObject path=\"");
      Dump.writePath(file, path, XML);
      File.write(file, "\"");
    then ();
  else
    algorithm
      Error.addInternalError("ScalarVariableType: "+Types.unparseType(t), sourceInfo());
    then fail();
  end match;
  File.write(file, " />");
end scalarVariableType;

function scalarVariableTypeUseAttribute
  input File.File file;
  input Option<Exp> startValue;
  input String use, name;
protected
  Exp exp;
algorithm
  File.write(file, use);
  _ := match startValue
  case SOME(exp)
    algorithm
      File.write(file, "=\"true\" ");
      File.write(file, name);
      File.write(file, "=\"");
      writeExp(file, exp);
      File.write(file, "\"");
    then ();
  else
    algorithm
      File.write(file, "=\"false\"");
    then ();
  end match;
end scalarVariableTypeUseAttribute;

function scalarVariableTypeFixedAttribute
  input File.File file;
  input Boolean isFixed;
algorithm
  File.write(file, " fixed=\"");
  File.write(file, String(isFixed));
  File.write(file, "\"");
end scalarVariableTypeFixedAttribute;

function scalarVariableTypeAttribute
  input File.File file;
  input Option<Exp> attr;
  input String name;
protected
  Exp exp;
algorithm
  _ := match attr
  case SOME(exp)
    algorithm
      File.write(file, " ");
      File.write(file, name);
      File.write(file, "=\"");
      writeExp(file, exp);
      File.write(file, "\"");
    then ();
  else ();
  end match;
end scalarVariableTypeAttribute;

function scalarVariableTypeStringAttribute
  input File.File file;
  input String attr;
  input String name;
algorithm
  if attr=="" then
    return;
  end if;
  File.write(file, " ");
  File.write(file, name);
  File.write(file, "=\"");
  File.writeEscape(file, attr, XML);
  File.write(file, "\"");
end scalarVariableTypeStringAttribute;

function getCausality "Returns the Causality Attribute of ScalarVariable."
  input Causality c;
  output String str;
algorithm
  str := match c
    case Causality.NONECAUS(__) then "none";
    case Causality.INTERNAL(__) then "internal";
    case Causality.OUTPUT(__) then "output";
    case Causality.INPUT(__) then "input";
  end match;
end getCausality;

function getVariablity "Returns the variablity Attribute of ScalarVariable."
  input VarKind varKind;
  output String str;
algorithm
  str := match varKind
  case VarKind.DISCRETE(__) then "discrete";
  case VarKind.PARAM(__) then "parameter";
  case VarKind.CONST(__) then "constant";
  else "continuous";
  end match;
end getVariablity;

function getAliasVar "Returns the alias Attribute of ScalarVariable."
  input File.File file;
  input SimCodeVar.SimVar simVar;
algorithm
  _ := match simVar
  local SimCodeVar.AliasVariable aliasvar;
  case SimCodeVar.SIMVAR(aliasvar = aliasvar as AliasVariable.ALIAS())
    algorithm
      File.write(file, "\"alias\" aliasVariable=\"");
      CR.writeCref(file, aliasvar.varName, XML);
      File.write(file, "\" aliasVariableId=\"");
      File.write(file, SimCodeUtil.getValueReference(simVar, SimCodeUtil.getSimCode(), true)+"\"");
    then ();
  case SimCodeVar.SIMVAR(aliasvar = aliasvar as AliasVariable.NEGATEDALIAS())
    algorithm
      File.write(file, "\"negatedAlias\" aliasVariable=\"");
      CR.writeCref(file, aliasvar.varName, XML);
      File.write(file, "\" aliasVariableId=\"");
      File.write(file, SimCodeUtil.getValueReference(simVar, SimCodeUtil.getSimCode(), true)+"\"");
      then ();
  else
    algorithm File.write(file, "\"noAlias\""); then ();
  end match;
end getAliasVar;

function xsdateTime "YYYY-MM-DDThh:mm:ssZ"
  input File.File file;
  input Util.DateTime dt;
algorithm
  File.writeInt(file, dt.year);
  File.writeInt(file, dt.mon, "-%02d");
  File.writeInt(file, dt.mday, "-%02d");
  File.writeInt(file, dt.hour, "T%02d");
  File.writeInt(file, dt.min, ":%02d");
  File.writeInt(file, dt.sec, ":%02dZ");
end xsdateTime;

function writeExp
  input File.File file;
  input Exp exp;
algorithm
  _ := match exp
  case Exp.ICONST(__) algorithm File.writeInt(file, exp.integer); then ();
  case Exp.RCONST(__) algorithm File.writeReal(file, exp.real); then ();
  case Exp.SCONST(__) algorithm File.writeEscape(file, exp.string, XML); then ();
  case Exp.BCONST(__) algorithm File.write(file, String(exp.bool)); then ();
  case Exp.ENUM_LITERAL(__) algorithm File.writeInt(file, exp.index); then ();
  else algorithm Error.addInternalError("initial value of unknown type: " + printExpStr(exp), sourceInfo()); then fail();
  end match;
end writeExp;

annotation(__OpenModelica_Interface="backend");
end SerializeInitXML;
