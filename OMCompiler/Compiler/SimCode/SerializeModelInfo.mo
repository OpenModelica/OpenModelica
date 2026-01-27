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

encapsulated package SerializeModelInfo

function serialize
  input SimCode.SimCode code;
  input Boolean withOperations;
  output String fileName;
algorithm
  (true,fileName) := serializeWork(code,withOperations);
end serialize;

import Absyn;
import BackendDAE;
import DAE;
import SimCode;

protected
import Algorithm;
import Autoconf;
import Config;
import DAEDump;
import Error;
import Expression;
import File;
import File.Escape.JSON;
import writeCref = ComponentReference.writeCref;
import expStr = ExpressionDump.printExpStr;
import List;
import PrefixUtil;
import SimCodeUtil;
import SimCodeFunctionUtil;
import SCodeDump;
import Util;
import UnorderedSet;

function serializeWork "Always succeeds in order to clean-up external objects"
  input SimCode.SimCode code;
  input Boolean withOperations;
  output Boolean success; // We always need to return in order to clean up external objects
  output String fileName;
protected
  File.File file = File.File();
algorithm
  (success,fileName) := matchcontinue code
    local
      SimCode.ModelInfo mi;
      String eqsName;
      list<SimCode.SimEqSystem> eqsLst;

    case SimCode.SIMCODE(modelInfo = mi as SimCode.MODELINFO())
      algorithm
        /*Temporary disabled omsicpp*/
        if (Config.simCodeTarget() == "omsic") /*or (Config.simCodeTarget() ==  "omsicpp") */ then
          fileName := code.fullPathPrefix + Autoconf.pathDelimiter + code.fileNamePrefix + "_info.json";
        else
          fileName := code.fileNamePrefix + "_info.json";
        end if;
        File.open(file,fileName,File.Mode.Write);
        File.write(file, "{\"format\":\"Transformational debugger info\",\"version\":1,\n\"info\":{\"name\":");
        serializePath(file, mi.name);
        File.write(file, ",\"description\":\"");
        File.writeEscape(file, mi.description, escape=JSON);
        File.write(file, "\"},\n\"variables\":{\n");
        serializeVars(file, mi.vars, withOperations);
        File.write(file, "\n},\n\"equations\":[");
        // Handle no comma for the first equation
        File.write(file,"{\"eqIndex\":0,\"tag\":\"dummy\"}");

        for tpl in {
          ("initial", code.initialEquations),
          ("initial-lambda0", code.initialEquations_lambda0),
          ("removed-initial", code.removedInitialEquations),
          ("regular", code.allEquations),
          ("synchronous", SimCodeUtil.getClockedEquations(SimCodeUtil.getSubPartitions(code.clockedPartitions))),
          ("start", code.startValueEquations),
          ("nominal", code.nominalValueEquations),
          ("min", code.minValueEquations),
          ("max", code.maxValueEquations),
          ("parameter", code.parameterEquations),
          ("assertions", code.algorithmAndEquationAsserts),
          ("inline", code.inlineEquations),
          ("residuals", List.flatten(SimCodeUtil.getSimCodeDAEModeDataEqns(code.daeModeData))),
          ("jacobian", code.jacobianEquations)
        } loop
          (eqsName, eqsLst) := tpl;
          for eq in SimCodeUtil.sortEqSystems(eqsLst) loop
            serializeEquation(file, eq, eqsName, withOperations);
          end for;
        end for;

        File.write(file, "\n],\n\"functions\":[");
        serializeList(file,mi.functions,serializeFunction);
        File.write(file, "\n]\n}");
      then (true,fileName);
    else
      equation
        Error.addInternalError("SerializeModelInfo.serialize failed", sourceInfo());
      then (false,"");
  end matchcontinue;
end serializeWork;

function serializeVars
  input File.File file;
  input SimCodeVar.SimVars vars;
  input Boolean withOperations;
protected
  Boolean b;
algorithm
  b := serializeVarsHelp(file, vars.stateVars, withOperations, true);
  b := serializeVarsHelp(file, vars.derivativeVars, withOperations, b);
  b := serializeVarsHelp(file, vars.algVars, withOperations, b);
  b := serializeVarsHelp(file, vars.intAlgVars, withOperations, b);
  b := serializeVarsHelp(file, vars.boolAlgVars, withOperations, b);
  b := serializeVarsHelp(file, vars.inputVars, withOperations, b);
  b := serializeVarsHelp(file, vars.intAliasVars, withOperations, b);
  b := serializeVarsHelp(file, vars.boolAliasVars, withOperations, b);
  b := serializeVarsHelp(file, vars.paramVars, withOperations, b);
  b := serializeVarsHelp(file, vars.intParamVars, withOperations, b);
  b := serializeVarsHelp(file, vars.boolParamVars, withOperations, b);
  b := serializeVarsHelp(file, vars.stringAlgVars, withOperations, b);
  b := serializeVarsHelp(file, vars.stringAliasVars, withOperations, b);
  b := serializeVarsHelp(file, vars.extObjVars, withOperations, b);
  b := serializeVarsHelp(file, vars.constVars, withOperations, b);
  b := serializeVarsHelp(file, vars.intConstVars, withOperations, b);
  b := serializeVarsHelp(file, vars.boolConstVars, withOperations, b);
  b := serializeVarsHelp(file, vars.stringConstVars, withOperations, b);
  b := serializeVarsHelp(file, vars.jacobianVars, withOperations, b);
  _ := serializeVarsHelp(file, vars.sensitivityVars, withOperations, b);
end serializeVars;

function serializeVarsHelp
  input File.File file;
  input list<SimCodeVar.SimVar> vars;
  input Boolean withOperations;
  input Boolean inFirst;
  output Boolean outFirst = inFirst and listEmpty(vars);
algorithm
  serializeList(file, vars, function serializeVar(withOperations = withOperations), not inFirst, ",\n");
end serializeVarsHelp;

function serializeVar
  input File.File file;
  input SimCodeVar.SimVar var;
  input Boolean withOperations;
algorithm
  File.write(file, "\"");
  writeCref(file, var.name, escape=JSON);
  File.write(file,"\":{\"comment\":\"");
  File.writeEscape(file,var.comment,escape=JSON);
  File.write(file,"\",\"kind\":\"");
  File.write(file, varKindString(var.varKind, var));
  File.write(file,"\"");
  serializeTypeName(file,var.type_);
  File.write(file,",\"unit\":\"");
  File.writeEscape(file,var.unit,escape=JSON);
  File.write(file,"\",\"displayUnit\":\"");
  File.writeEscape(file,var.displayUnit,escape=JSON);
  File.write(file,"\",\"source\":");
  serializeSource(file,var.source,withOperations);
  File.write(file, ",\"index\":");
  File.writeInt(file, var.index);
  File.write(file,"}");
end serializeVar;

function serializeTypeName
  input File.File file;
  input DAE.Type ty;
algorithm
  () := match ty
    case DAE.T_REAL() equation File.write(file,",\"type\":\"Real\""); then ();
    case DAE.T_INTEGER() equation File.write(file,",\"type\":\"Integer\""); then ();
    case DAE.T_BOOL() equation File.write(file,",\"type\":\"Boolean\""); then ();
    case DAE.T_STRING() equation File.write(file,",\"type\":\"String\""); then ();
    case DAE.T_ENUMERATION() equation File.write(file,",\"type\":\"Enumeration\""); then ();
    else ();
  end match;
end serializeTypeName;

function serializeSource
  input File.File file;
  input DAE.ElementSource source;
  input Boolean withOperations;
protected
  SourceInfo info;
  list<Absyn.Path> paths,typeLst;
  list<Absyn.Within> partOfLst;
  DAE.ComponentPrefix instance;
  Integer i;
  list<DAE.SymbolicOperation> operations;
algorithm
  DAE.SOURCE(typeLst=typeLst,info=info,instance=instance,partOfLst=partOfLst,operations=operations) := source;
  File.write(file,"{");
  serializeInfo(file,info);

  if not listEmpty(partOfLst) then
    paths := list(match w case Absyn.WITHIN() then w.path; end match
                  for w guard (match w case Absyn.TOP() then false; else true; end match)
                  in partOfLst);
    File.write(file,",\"within\":[");
    serializeList(file,paths,serializePath);
    File.write(file,"]");
  end if;

  () := match instance
  case DAE.NOCOMPPRE() then ();
  case DAE.PRE() algorithm
    File.write(file,",\"instance\":\"");
    PrefixUtil.writeComponentPrefix(file,instance,escape=JSON);
    File.write(file,"\"");
  then ();
  end match;

  if not listEmpty(typeLst) then
    File.write(file,",\"typeLst\":[");
    serializeList(file,typeLst,serializePath);
    File.write(file,"]");
  end if;

  if withOperations and not listEmpty(operations) then
    File.write(file,",\"operations\":[");
    serializeList(file, operations, serializeOperation);
    File.write(file,"]");
  end if;
  File.write(file,"}");
end serializeSource;

function serializeInfo
  input File.File file;
  input SourceInfo info;
algorithm
  File.write(file,"\"info\":{\"file\":\"");
  File.writeEscape(file, info.fileName, escape=JSON);
  File.write(file, "\",\"lineStart\":");
  File.writeInt(file, info.lineNumberStart);
  File.write(file, ",\"lineEnd\":");
  File.writeInt(file, info.lineNumberEnd);
  File.write(file, ",\"colStart\":");
  File.writeInt(file, info.columnNumberStart);
  File.write(file, ",\"colEnd\":");
  File.writeInt(file, info.columnNumberEnd);
  File.write(file, "}");
end serializeInfo;

function serializeOperation
  input File.File file;
  input DAE.SymbolicOperation op;
algorithm
  _ := match op
    local
      DAE.Element elt;
    case DAE.FLATTEN(dae=SOME(elt))
      equation
        File.write(file,"{\"op\":\"before-after\",\"display\":\"flattening\",\"data\":[\"");
        File.writeEscape(file,System.trim(SCodeDump.equationStr(op.scode,SCodeDump.defaultOptions)),escape=JSON);
        File.write(file,"\",\"");
        File.writeEscape(file,System.trim(DAEDump.dumpEquationStr(elt)),escape=JSON);
        File.write(file,"\"]}");
      then ();
    case DAE.FLATTEN()
      equation
        File.write(file,"{\"op\":\"info\",\"display\":\"scode\",\"data\":[\"");
        File.writeEscape(file,System.trim(SCodeDump.equationStr(op.scode,SCodeDump.defaultOptions)),escape=JSON);
        File.write(file,"\"]}");
      then ();
    case DAE.SIMPLIFY()
      equation
        File.write(file,"{\"op\":\"before-after\",\"display\":\"simplify\",\"data\":[\"");
        writeEqExpStr(file,op.before);
        File.write(file,"\",\"");
        writeEqExpStr(file,op.after);
        File.write(file,"\"]}");
      then ();
    case DAE.OP_INLINE()
      equation
        File.write(file,"{\"op\":\"before-after\",\"display\":\"inline\",\"data\":[\"");
        writeEqExpStr(file,op.before);
        File.write(file,"\",\"");
        writeEqExpStr(file,op.after);
        File.write(file,"\"]}");
      then ();
    case DAE.SOLVE(assertConds={})
      equation
        File.write(file,"{\"op\":\"before-after\",\"display\":\"solved\",\"data\":[\"");
        File.writeEscape(file,expStr(op.exp1),escape=JSON);
        File.write(file," = ");
        File.writeEscape(file,expStr(op.exp2),escape=JSON);
        File.write(file,"\",\"");
        writeCref(file,op.cr,escape=JSON);
        File.write(file," = ");
        File.writeEscape(file,expStr(op.res),escape=JSON);
        File.write(file,"\"]}");
      then ();
    case DAE.SOLVE()
      algorithm
        File.write(file,"{\"op\":\"before-after-assert\",\"display\":\"solved\",\"data\":[\"");
        File.writeEscape(file,expStr(op.exp1),escape=JSON);
        File.write(file," = ");
        File.writeEscape(file,expStr(op.exp2),escape=JSON);
        File.write(file,"\",\"");
        writeCref(file,op.cr,escape=JSON);
        File.write(file," = ");
        File.writeEscape(file,expStr(op.res),escape=JSON);
        File.write(file,"\"");
        serializeList(file, op.assertConds, serializeExp, true);
        File.write(file,"]}");
      then ();
    case DAE.OP_RESIDUAL()
      equation
        File.write(file,"{\"op\":\"before-after\",\"display\":\"residual\",\"data\":[");
        File.writeEscape(file,expStr(op.e1),escape=JSON);
        File.write(file," = ");
        File.writeEscape(file,expStr(op.e2),escape=JSON);
        File.write(file,",\"0 = ");
        File.writeEscape(file,expStr(op.e),escape=JSON);
        File.write(file,"\"]}");
      then ();
    case DAE.SUBSTITUTION()
      equation
        File.write(file,"{\"op\":\"chain\",\"display\":\"substitution\",\"data\":[\"");
        File.writeEscape(file,expStr(op.source),escape=JSON);
        File.write(file,"\"");
        serializeList(file, op.substitutions, serializeExp, true);
        File.write(file,"]}");
      then ();
    case DAE.SOLVED()
      equation
        File.write(file,"{\"op\":\"info\",\"display\":\"solved\",\"data\":[\"");
        writeCref(file,op.cr,escape=JSON);
        File.write(file," = ");
        File.writeEscape(file,expStr(op.exp),escape=JSON);
        File.write(file,"\"]}");
      then ();
    case DAE.OP_DIFFERENTIATE()
      equation
        File.write(file,"{\"op\":\"before-after\",\"display\":\"differentiate d/d");
        writeCref(file,op.cr,escape=JSON);
        File.write(file,"\",\"data\":[\"");
        File.writeEscape(file,expStr(op.before),escape=JSON);
        File.write(file,"\",\"");
        File.writeEscape(file,expStr(op.after),escape=JSON);
        File.write(file,"\"]}");
      then ();

    case DAE.OP_SCALARIZE()
      equation
        File.write(file,"{\"op\":\"before-after\",\"display\":\"scalarize [");
        File.write(file,intString(op.index));
        File.write(file,"]\",\"data\":[\"");
        writeEqExpStr(file,op.before);
        File.write(file,"\",\"");
        writeEqExpStr(file,op.after);
        File.write(file,"\"]}");
      then ();

      // Custom operations - operations that can not be described in a general way because they are specialized
    case DAE.NEW_DUMMY_DER()
      equation
        File.write(file,"{\"op\":\"dummy-der\",\"display\":\"dummy derivative");
        File.write(file,"\",\"data\":[\"");
        writeCref(file,op.chosen);
        File.write(file,"\"");
        serializeList(file, op.candidates, serializeCref, true);
        File.write(file,"]}");
      then ();

    else
      equation
        Error.addInternalError("serializeOperation failed: " + anyString(op), sourceInfo());
      then fail();
  end match;
end serializeOperation;

type AssignType = enumeration(NORMAL, TORN, JACOBIAN);

function tagFromAssignType
  input AssignType assignType;
  output String tag;
algorithm
  tag := match assignType
    case AssignType.NORMAL then "assign";
    case AssignType.TORN then "torn";
    case AssignType.JACOBIAN then "jacobian";
  end match;
end tagFromAssignType;

function serializeEquation
  input File.File file;
  input SimCode.SimEqSystem eq;
  input String section;
  input Boolean withOperations;
  input Integer parent = 0 "No parent";
  input Boolean first = false;
  input AssignType assign_type = AssignType.NORMAL;
algorithm
  if not first then
    File.write(file, ",");
  end if;
  () := match eq
    local
      Integer i,j;
      DAE.Statement stmt;
      list<SimCode.SimEqSystem> eqs,jeqs,constantEqns;
      SimCode.LinearSystem lSystem, atL;
      SimCode.NonlinearSystem nlSystem, atNL;
      BackendDAE.WhenOperator whenOp;
      list<DAE.ComponentRef> crefs;

    case SimCode.SES_RESIDUAL() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"residual\",\"uses\":[");
      serializeList(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp), serializeCref);
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_FOR_RESIDUAL() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"residual\",\"uses\":[");
      serializeList(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp), serializeCref);
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_GENERIC_RESIDUAL() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"residual\",\"uses\":[");
      serializeList(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp), serializeCref);
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_SIMPLE_ASSIGN() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"" + tagFromAssignType(assign_type) + "\",\"defines\":[\"");
      writeCref(file,eq.cref,escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeList(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp), serializeCref);
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_RESIZABLE_ASSIGN() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"" + tagFromAssignType(assign_type) + "\",\"defines\":[\"");
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_GENERIC_ASSIGN() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"" + tagFromAssignType(assign_type) + "\",\"defines\":[\"");
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_ENTWINED_ASSIGN() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"" + tagFromAssignType(assign_type) + "\",\"defines\":[\"");
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"" + tagFromAssignType(assign_type) + "\",\"defines\":[\"");
      writeCref(file,eq.cref,escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeList(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp), serializeCref);
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_ARRAY_CALL_ASSIGN() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"" + tagFromAssignType(assign_type) + "\",\"defines\":[\"");
      writeCref(file,Expression.expCref(eq.lhs),escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeList(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp), serializeCref);
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    // no dynamic tearing
    case SimCode.SES_LINEAR(lSystem = lSystem as SimCode.LINEARSYSTEM(), alternativeTearing = NONE()) algorithm
      i := listLength(lSystem.beqs);
      j := listLength(lSystem.simJac);

      eqs := SimCodeUtil.sortEqSystems(lSystem.residual);
      if not listEmpty(eqs) then
        serializeEquation(file,listHead(eqs),section,withOperations,parent=lSystem.index,first=true,assign_type=if lSystem.tornSystem then AssignType.TORN else AssignType.NORMAL);
        for e in listRest(eqs) loop serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=if lSystem.tornSystem then AssignType.TORN else AssignType.NORMAL); end for;
      end if;

      jeqs := match lSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=lSystem.index,first=true,assign_type=AssignType.JACOBIAN);
        for e in listRest(jeqs) loop serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=AssignType.JACOBIAN); end for;
      end if;

      if listEmpty(eqs) and listEmpty(jeqs) then
        File.write(file, "\n{\"eqIndex\":");
      else
        File.write(file, ",\n{\"eqIndex\":");
      end if;
      File.writeInt(file, lSystem.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);

      // Ax=b
      if lSystem.tornSystem then
        File.write(file, "\",\"tag\":\"tornsystem\"");
      else
        File.write(file, "\",\"tag\":\"system\"");
      end if;

      File.write(file, ",\"display\":\"linear\",\"unknowns\":" + intString(lSystem.nUnknowns) + ",\"defines\":[");
      serializeList(file, list(v.name for v in lSystem.vars), serializeCref);
      File.write(file, "],\"equation\":[{\"size\":");
      File.write(file,intString(i));
      if i <> 0 then
        File.write(file,",\"density\":");
        File.writeReal(file,j / (i*i),format="%.2f");
      end if;
      File.write(file,",\"A\":[");
      serializeList(file, lSystem.simJac, function serializeLinearCell(withOperations = withOperations));
      File.write(file,"],\"b\":[");
      serializeList(file,lSystem.beqs,serializeExp);
      File.write(file,"]}]}");
    then ();

    // dynamic tearing
    case SimCode.SES_LINEAR(lSystem = lSystem as SimCode.LINEARSYSTEM(), alternativeTearing = SOME(atL as SimCode.LINEARSYSTEM())) algorithm
      // for strict tearing set
      i := listLength(lSystem.beqs);
      j := listLength(lSystem.simJac);

      eqs := SimCodeUtil.sortEqSystems(lSystem.residual);
      if not listEmpty(eqs) then
        serializeEquation(file,listHead(eqs),section,withOperations,parent=lSystem.index,first=true,assign_type=if lSystem.tornSystem then AssignType.TORN else AssignType.NORMAL);
        for e in listRest(eqs) loop serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=if lSystem.tornSystem then AssignType.TORN else AssignType.NORMAL); end for;
      end if;

      jeqs := match lSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=lSystem.index,first=true,assign_type=AssignType.JACOBIAN);
        for e in listRest(jeqs) loop serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=AssignType.JACOBIAN); end for;
      end if;

      if listEmpty(eqs) and listEmpty(jeqs) then
        File.write(file, "\n{\"eqIndex\":");
      else
        File.write(file, ",\n{\"eqIndex\":");
      end if;
      File.writeInt(file, lSystem.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);

      // Ax=b
      if lSystem.tornSystem then
        File.write(file, "\",\"tag\":\"tornsystem\"");
      else
        File.write(file, "\",\"tag\":\"system\"");
      end if;

      File.write(file, ",\"display\":\"linear\",\"unknowns\":" + intString(lSystem.nUnknowns) + ",\"defines\":[");
      serializeList(file, list(v.name for v in lSystem.vars), serializeCref);
      File.write(file, "],\"equation\":[{\"size\":");
      File.write(file,intString(i));
      if i <> 0 then
        File.write(file,",\"density\":");
        File.writeReal(file,j / (i*i),format="%.2f");
      end if;
      File.write(file,",\"A\":[");
      serializeList(file, lSystem.simJac, function serializeLinearCell(withOperations = withOperations));
      File.write(file,"],\"b\":[");
      serializeList(file,lSystem.beqs,serializeExp);
      File.write(file,"]}]},");

      // for casual tearing set
      i := listLength(atL.beqs);
      j := listLength(atL.simJac);

      eqs := SimCodeUtil.sortEqSystems(atL.residual);
      if not listEmpty(eqs) then
        serializeEquation(file,listHead(eqs),section,withOperations,parent=atL.index,first=true,assign_type=if atL.tornSystem then AssignType.TORN else AssignType.NORMAL);
        for e in listRest(eqs) loop serializeEquation(file,e,section,withOperations,parent=atL.index,assign_type=if atL.tornSystem then AssignType.TORN else AssignType.NORMAL); end for;
      end if;

      jeqs := match atL.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=atL.index,first=true,assign_type=AssignType.JACOBIAN);
        for e in listRest(jeqs) loop serializeEquation(file,e,section,withOperations,parent=atL.index,assign_type=AssignType.JACOBIAN); end for;
      end if;

      if listEmpty(eqs) and listEmpty(jeqs) then
        File.write(file, "\n{\"eqIndex\":");
      else
        File.write(file, ",\n{\"eqIndex\":");
      end if;
      File.writeInt(file, atL.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);

      // Ax=b
      if atL.tornSystem then
        File.write(file, "\",\"tag\":\"tornsystem\"");
      else
        File.write(file, "\",\"tag\":\"system\"");
      end if;

      File.write(file, ",\"display\":\"linear\",\"unknowns\":" + intString(atL.nUnknowns) + ",\"defines\":[");
      serializeList(file, list(v.name for v in atL.vars), serializeCref);
      File.write(file, "],\"equation\":[{\"size\":");
      File.write(file,intString(i));
      if i <> 0 then
        File.write(file,",\"density\":");
        File.writeReal(file,j / (i*i),format="%.2f");
      end if;
      File.write(file,",\"A\":[");
      serializeList(file, atL.simJac, function serializeLinearCell(withOperations = withOperations));
      File.write(file,"],\"b\":[");
      serializeList(file,atL.beqs,serializeExp);
      File.write(file,"]}]}");
    then ();

    case SimCode.SES_ALGORITHM(statements={stmt as DAE.STMT_ASSIGN()}) algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section + "\",\"tag\":\"algorithm\",\"defines\":[\"");
      writeCref(file, Expression.expCref(stmt.exp1),escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeList(file, Expression.extractUniqueCrefsFromExpDerPreStart(stmt.exp), serializeCref);
      File.write(file, "],\"equation\":[");
      serializeList(file,eq.statements,serializeStatement);
      File.write(file, "],\"source\":");
      serializeSource(file,Algorithm.getStatementSource(stmt),withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_ALGORITHM(statements=stmt::_) algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section + "\",\"tag\":\"algorithm\",\"equation\":[");
      serializeList(file,eq.statements,serializeStatement);
      File.write(file, "],\"source\":");
      serializeSource(file,Algorithm.getStatementSource(stmt),withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_INVERSE_ALGORITHM(statements=stmt::_) algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section + "\",\"tag\":\"algorithm\",\"equation\":[");
      serializeList(file,eq.statements,serializeStatement);
      File.write(file, "],\"source\":");
      serializeSource(file,Algorithm.getStatementSource(stmt),withOperations);
      File.write(file, "}");
    then ();

    // no dynamic tearing
    case SimCode.SES_NONLINEAR(nlSystem = nlSystem as SimCode.NONLINEARSYSTEM(), alternativeTearing = NONE()) algorithm
      eqs := SimCodeUtil.sortEqSystems(nlSystem.eqs);
      serializeEquation(file,listHead(eqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=if nlSystem.tornSystem then AssignType.TORN else AssignType.NORMAL);
      for e in listRest(eqs) loop serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=if nlSystem.tornSystem then AssignType.TORN else AssignType.NORMAL); end for;

      jeqs := match nlSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=AssignType.JACOBIAN);
        for e in listRest(jeqs) loop serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=AssignType.JACOBIAN); end for;
      end if;

      File.write(file, ",\n{\"eqIndex\":");
      File.writeInt(file, nlSystem.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);

      if nlSystem.tornSystem then
        File.write(file, "\",\"tag\":\"tornsystem\"");
      else
        File.write(file, "\",\"tag\":\"system\"");
      end if;

      File.write(file, ",\"display\":\"non-linear\",\"unknowns\":" + intString(nlSystem.nUnknowns) + ",\"defines\":[");
      serializeList(file, nlSystem.crefs, serializeCref);
      File.write(file, "],\"equation\":[[");
      serializeList(file,eqs,serializeEquationIndex);
      File.write(file, "],[");
      serializeList(file,jeqs,serializeEquationIndex);
      File.write(file, "]]}");
    then ();

    // dynamic tearing
    case SimCode.SES_NONLINEAR(nlSystem = nlSystem as SimCode.NONLINEARSYSTEM(), alternativeTearing = SOME(atNL as SimCode.NONLINEARSYSTEM())) algorithm
      // for strict tearing set
      eqs := SimCodeUtil.sortEqSystems(nlSystem.eqs);
      serializeEquation(file,listHead(eqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=if nlSystem.tornSystem then AssignType.TORN else AssignType.NORMAL);
      for e in listRest(eqs) loop serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=if nlSystem.tornSystem then AssignType.TORN else AssignType.NORMAL); end for;

      jeqs := match nlSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=AssignType.JACOBIAN);
        for e in listRest(jeqs) loop serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=AssignType.JACOBIAN); end for;
      end if;

      File.write(file, ",\n{\"eqIndex\":");
      File.writeInt(file, nlSystem.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);

      if nlSystem.tornSystem then
        File.write(file, "\",\"tag\":\"tornsystem\"");
      else
        File.write(file, "\",\"tag\":\"system\"");
      end if;

      File.write(file, ",\"display\":\"non-linear\",\"unknowns\":" + intString(nlSystem.nUnknowns) + ",\"defines\":[");
      serializeList(file, nlSystem.crefs, serializeCref);
      File.write(file, "],\"equation\":[[");
      serializeList(file,eqs,serializeEquationIndex);
      File.write(file, "],[");
      serializeList(file,jeqs,serializeEquationIndex);
      File.write(file, "]]},");

      // for casual tearing set
      eqs := SimCodeUtil.sortEqSystems(atNL.eqs);
      serializeEquation(file,listHead(eqs),section,withOperations,parent=atNL.index,first=true,assign_type=if atNL.tornSystem then AssignType.TORN else AssignType.NORMAL);
      for e in listRest(eqs) loop serializeEquation(file,e,section,withOperations,parent=atNL.index,assign_type=if atNL.tornSystem then AssignType.TORN else AssignType.NORMAL); end for;

      jeqs := match atNL.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=atNL.index,first=true,assign_type=AssignType.JACOBIAN);
        for e in listRest(jeqs) loop serializeEquation(file,e,section,withOperations,parent=atNL.index,assign_type=AssignType.JACOBIAN); end for;
      end if;

      File.write(file, ",\n{\"eqIndex\":");
      File.writeInt(file, atNL.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);

      if atNL.tornSystem then
        File.write(file, "\",\"tag\":\"tornsystem\"");
      else
        File.write(file, "\",\"tag\":\"system\"");
      end if;

      File.write(file, ",\"display\":\"non-linear\",\"unknowns\":" + intString(atNL.nUnknowns) + ",\"defines\":[");
      serializeList(file, atNL.crefs, serializeCref);
      File.write(file, "],\"equation\":[[");
      serializeList(file,eqs,serializeEquationIndex);
      File.write(file, "],[");
      serializeList(file,jeqs,serializeEquationIndex);
      File.write(file, "]]}");
    then ();

    case SimCode.SES_IFEQUATION() algorithm
      eqs := listAppend(List.flatten(list(Util.tuple22(e) for e in eq.ifbranches)), eq.elsebranch);
      serializeEquation(file,listHead(eqs),section,withOperations,first=true);
      for e in listRest(eqs) loop serializeEquation(file,e,section,withOperations); end for;
      File.write(file, ",\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"if-equation\",\"display\":\"if-equation\",\"equation\":[");
      serializeList(file,eq.ifbranches,serializeIfBranch);
      File.write(file, ",");
      serializeIfBranch(file,(DAE.BCONST(true),eq.elsebranch));
      File.write(file, "]}");
    then ();

    case SimCode.SES_MIXED() algorithm
      serializeEquation(file,eq.cont,section,withOperations,first=true);
      for e in eq.discEqs loop serializeEquation(file,e,section,withOperations); end for;
      File.write(file, ",\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"container\",\"display\":\"mixed\",\"defines\":[");
      serializeList(file, list(v.name for v in eq.discVars), serializeCref);
      File.write(file, "],\"equation\":[");
      serializeEquationIndex(file,eq.cont);
      for e1 in eq.discEqs loop
        File.write(file,",");
        serializeEquationIndex(file,e1);
      end for;
      File.write(file, "]}");
    then ();

    case SimCode.SES_WHEN() algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      for whenOps in eq.whenStmtLst loop
        () := match whenOps
          case whenOp as BackendDAE.ASSIGN() algorithm
            File.write(file, "\",\"tag\":\"when\",\"defines\":[");
            serializeExp(file,whenOp.left);
            File.write(file, "],\"uses\":[");
            serializeList(file, getWhenUses(eq.conditions, whenOp.right), serializeCref);
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.right);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.REINIT() algorithm
            File.write(file, "\",\"tag\":\"when\",\"defines\":[");
            serializeCref(file,whenOp.stateVar);
            File.write(file, "],\"uses\":[");
            serializeList(file, getWhenUses(eq.conditions, whenOp.value), serializeCref);
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.value);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.ASSERT() algorithm
            File.write(file, "\",\"tag\":\"when\"");
            File.write(file, ",\"uses\":[");
            crefs := Expression.extractCrefsFromExpDerPreStart(whenOp.condition);
            serializeList(file, getWhenUses(crefs, whenOp.message), serializeCref);
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.message);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.TERMINATE() algorithm
            File.write(file, "\",\"tag\":\"when\"");
            File.write(file, ",\"uses\":[");
            serializeList(file, getWhenUses(eq.conditions, whenOp.message), serializeCref);
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.message);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.NORETCALL() algorithm
            File.write(file, "\",\"tag\":\"when\"");
            File.write(file, ",\"uses\":[");
            serializeList(file, getWhenUses(eq.conditions, whenOp.exp), serializeCref);
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.exp);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
        end match;
      end for;
      () := match eq.elseWhen
        local
          SimCode.SimEqSystem e;
        case SOME(e) algorithm
          if SimCodeUtil.simEqSystemIndex(e) <>0 then
            serializeEquation(file,e,section,withOperations);
          end if;
        then ();
        else ();
      end match;
    then ();

    case SimCode.SES_FOR_LOOP() algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      File.write(file, "\",\"tag\":\"" + tagFromAssignType(assign_type) + "\",\"defines\":[\"");
      writeCref(file,eq.cref,escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeList(file, Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp), serializeCref);
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then ();

    case SimCode.SES_ALIAS() algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      File.write(file, ",\"tag\":\"alias\",\"equation\":[");
      File.writeInt(file, eq.aliasOf);
      File.write(file, "],\"section\":\"");
      File.write(file, section);
      File.write(file, "\"}");
    then ();

    else algorithm
      Error.addInternalError("serializeEquation failed: " + anyString(eq), sourceInfo());
    then fail();
  end match;
end serializeEquation;

function serializeLinearCell
  input File.File file;
  input tuple<Integer, Integer, SimCode.SimEqSystem> cell;
  input Boolean withOperations;
algorithm
  _ := match cell
    local
      Integer i,j;
      SimCode.SimEqSystem eq;
    case (i,j,eq as SimCode.SES_RESIDUAL())
      equation
        File.write(file,"{\"row\":");
        File.write(file,intString(i));
        File.write(file,",\"column\":");
        File.write(file,intString(j));
        File.write(file,",\"exp\":\"");
        File.writeEscape(file,expStr(eq.exp),escape=JSON);
        File.write(file,"\",\"source\":");
        serializeSource(file,eq.source,withOperations);
        File.write(file,"}");
      then ();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SerializeModelInfo.serializeLinearCell failed. Expected only SES_RESIDUAL as input."});
      then fail();
  end match;
end serializeLinearCell;

function varKindString
  input BackendDAE.VarKind varKind;
  input SimCodeVar.SimVar var;
  output String str;
algorithm
  str := match varKind
    case BackendDAE.VARIABLE() then "variable";
    case BackendDAE.STATE() then "state"; // Output number of times it was differentiated?
    case BackendDAE.STATE_DER() then "derivative";
    case BackendDAE.DUMMY_DER() then "dummy derivative";
    case BackendDAE.DUMMY_STATE() then "dummy state";
    case BackendDAE.CLOCKED_STATE() then "clocked state";
    case BackendDAE.DISCRETE() then "discrete";
    case BackendDAE.PARAM() then "parameter";
    case BackendDAE.CONST() then "constant";
    case BackendDAE.EXTOBJ() then "external object";
    case BackendDAE.JAC_VAR() then "jacobian variable";
    case BackendDAE.JAC_TMP_VAR() then "jacobian differentiated variable";
    case BackendDAE.OPT_CONSTR() then "constraint";
    case BackendDAE.OPT_FCONSTR() then "final constraint";
    case BackendDAE.OPT_INPUT_WITH_DER() then "use derivation of input";
    case BackendDAE.OPT_INPUT_DER() then "derivation of input";
    case BackendDAE.OPT_TGRID() then "time grid for optimization";
    case BackendDAE.OPT_LOOP_INPUT() then "variable for transform loop in constraint";
    case BackendDAE.ALG_STATE() then "helper variable transform ode for symSolver";
    case BackendDAE.ALG_STATE_OLD() then "helper variable transform ode for symSolver";
    case BackendDAE.LOOP_ITERATION() then "iteration variable for solving an algebraic loop";
    case BackendDAE.DAE_RESIDUAL_VAR() then "residual variable for dae mode";
    else
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed for " + SimCodeUtil.simVarString(var)});
      then fail();
  end match;
end varKindString;

function getWhenUses
  input list<DAE.ComponentRef> conditions;
  input DAE.Exp value;
  output list<DAE.ComponentRef> uses;
algorithm
  uses := listAppend(conditions, Expression.extractCrefsFromExpDerPreStart(value));
  uses := UnorderedSet.unique_list(uses, ComponentReference.hashComponentRef, ComponentReference.crefEqual);
end getWhenUses;

function serializeStatement
  input File.File file;
  input DAE.Statement stmt;
algorithm
  File.write(file,"\"");
  File.writeEscape(file, System.trim(DAEDump.ppStatementStr(stmt)), escape=JSON);
  File.write(file,"\"");
end serializeStatement;

function serializeList<ArgType>
  input File.File file;
  input list<ArgType> lst;
  input FuncType func;
  input Boolean append = false  "start with sep";
  input String sep = ","        "separator between elements";

  partial function FuncType
    input File.File file;
    input ArgType a;
  end FuncType;
algorithm
  if not listEmpty(lst) then
    if append then
      File.write(file, sep);
    end if;
    func(file, listHead(lst));
    for a in listRest(lst) loop
      File.write(file, sep);
      func(file, a);
    end for;
  end if;
end serializeList;

function serializeExp
  input File.File file;
  input DAE.Exp exp;
algorithm
  File.write(file, "\"");
  File.writeEscape(file, expStr(exp), escape=JSON);
  File.write(file, "\"");
end serializeExp;

function serializeCref
  input File.File file;
  input DAE.ComponentRef cr;
algorithm
  File.write(file, "\"");
  writeCref(file, cr, escape=JSON);
  File.write(file, "\"");
end serializeCref;

function serializeString
  input File.File file;
  input String string;
algorithm
  File.write(file, "\"");
  File.writeEscape(file, string, escape=JSON);
  File.write(file, "\"");
end serializeString;

function serializePath
  input File.File file;
  input Absyn.Path path;
protected
  Absyn.Path p=path;
  Boolean b=true;
algorithm
  File.write(file, "\"");
  while b loop
    (p,b) := match p
      case Absyn.IDENT()
        algorithm
          File.writeEscape(file, p.name, escape=JSON);
        then (p,false);
      case Absyn.QUALIFIED()
        algorithm
          File.writeEscape(file, p.name, escape=JSON);
          File.write(file, ".");
        then (p.path,true);
      case Absyn.FULLYQUALIFIED()
        then (p.path,true);
    end match;
  end while;
  File.write(file, "\"");
end serializePath;

function serializeEquationIndex
  input File.File file;
  input SimCode.SimEqSystem eq;
algorithm
  File.writeInt(file, SimCodeUtil.simEqSystemIndex(eq));
end serializeEquationIndex;

function serializeIfBranch
  input File.File file;
  input tuple<DAE.Exp,list<SimCode.SimEqSystem>> branch;
protected
  DAE.Exp exp;
  list<SimCode.SimEqSystem> eqs;
algorithm
  (exp,eqs) := branch;
  File.write(file,"[");
  serializeExp(file,exp);
  serializeList(file, eqs, serializeEquationIndex, true);
  File.write(file,"]");
end serializeIfBranch;

function writeEqExpStr
  input File.File file;
  input DAE.EquationExp eqExp;
algorithm
  () := match eqExp
    case DAE.PARTIAL_EQUATION()
      algorithm
        File.writeEscape(file,expStr(eqExp.exp),escape=JSON);
      then ();
    case DAE.RESIDUAL_EXP()
      algorithm
        File.write(file,"0 = ");
        File.writeEscape(file,expStr(eqExp.exp),escape=JSON);
      then ();
    case DAE.EQUALITY_EXPS()
      algorithm
        File.writeEscape(file,expStr(eqExp.lhs),escape=JSON);
        File.write(file," = ");
        File.writeEscape(file,expStr(eqExp.rhs),escape=JSON);
      then ();
  end match;
end writeEqExpStr;

function serializeFunction
  input File.File file;
  input SimCodeFunction.Function func;
algorithm
  File.write(file, "\n");
  serializePath(file, SimCodeUtil.functionPath(func));
end serializeFunction;

annotation(__OpenModelica_Interface="backend");
end SerializeModelInfo;
