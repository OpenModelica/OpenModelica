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

encapsulated package SerializeTaskSystemInfo

import Absyn;
import BackendDAE;
import DAE;
import SimCode;

protected
import Algorithm;
import DAEDump;
import Error;
import Expression;
import File;
import File.Escape.JSON;
import writeCref = ComponentReference.writeCref;
import expStr = ExpressionDump.printExpStr;
import List;
import SimCodeUtil;
import SimCodeFunctionUtil;
import Util;

public
function serializeParMod
  input SimCode.SimCode code;
  input Boolean withOperations;
  output String fileName;
algorithm
  (true,fileName) := serializeParModWork(code,withOperations);
end serializeParMod;

protected
function serializeParModWork "Always succeeds in order to clean-up external objects"
  input SimCode.SimCode code;
  input Boolean withOperations;
  output Boolean success; // We always need to return in order to clean up external objects
  output String fileName;
protected
  File.File file = File.File();
  SimCode.ModelInfo mi;
  SimCodeVar.SimVars vars;
algorithm
  try
    SimCode.SIMCODE(modelInfo=mi as SimCode.MODELINFO(vars=vars)) := code;
    fileName := code.fileNamePrefix + "_ode.json";
    File.open(file,fileName,File.Mode.Write);
    File.write(file, "{\"format\":\"ParModelica task system info\",\"version\":1,\n\"info\":{\"name\":");
    serializePath(file, mi.name);
    File.write(file, ",\"description\":\"");
    File.writeEscape(file, mi.description, escape=JSON);
    File.write(file, "\"},\n\"ode-equations\":[");
    // Handle no comma for the first equation
    File.write(file,"{\"eqIndex\":0,\"tag\":\"dummy\"}");
    min(serializeEquation(file,eq,"regular",withOperations) for eq in SimCodeUtil.sortEqSystems(List.flatten(code.odeEquations)));
    File.write(file, "\n]\n}");
    // file.close();
    success := true;
  else
    Error.addInternalError("SerializeTaskSystemInfo.serializeParModWork failed", sourceInfo());
    success := false;
  end try;
end serializeParModWork;

function serializeEquation
  input File.File file;
  input SimCode.SimEqSystem eq;
  input String section;
  input Boolean withOperations;
  input Integer parent = 0 "No parent";
  input Boolean first = false;
  input Integer assign_type = 0 "0: normal equation, 1: torn equation, 2: jacobian equation";
  output Boolean success;
algorithm
  if not first then
    File.write(file, ",");
  end if;
  success := match eq
    local
      Integer i,j;
      DAE.Statement stmt;
      list<SimCode.SimEqSystem> eqs,jeqs,constantEqns;
      SimCode.LinearSystem lSystem, atL;
      SimCode.NonlinearSystem nlSystem, atNL;
      BackendDAE.WhenOperator whenOp;
      list<DAE.ComponentRef> crefs, crefs2;

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
      serializeUses(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp));
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then true;

    case SimCode.SES_SIMPLE_ASSIGN() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      if (assign_type==1) then
        File.write(file, "\",\"tag\":\"torn\",\"defines\":[\"");
      elseif (assign_type==2) then
        File.write(file, "\",\"tag\":\"jacobian\",\"defines\":[\"");
      else
        File.write(file, "\",\"tag\":\"assign\",\"defines\":[\"");
      end if;
      writeCref(file,eq.cref,escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeUses(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp));
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then true;

    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      if (assign_type==1) then
        File.write(file, "\",\"tag\":\"torn\",\"defines\":[\"");
      elseif (assign_type==2) then
        File.write(file, "\",\"tag\":\"jacobian\",\"defines\":[\"");
      else
        File.write(file, "\",\"tag\":\"assign\",\"defines\":[\"");
      end if;
      writeCref(file,eq.cref,escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeUses(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp));
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then true;

    case SimCode.SES_ARRAY_CALL_ASSIGN() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      if (assign_type==1) then
        File.write(file, "\",\"tag\":\"torn\",\"defines\":[\"");
      elseif (assign_type==2) then
        File.write(file, "\",\"tag\":\"jacobian\",\"defines\":[\"");
      else
        File.write(file, "\",\"tag\":\"assign\",\"defines\":[\"");
      end if;
      writeCref(file,Expression.expCref(eq.lhs),escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeUses(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp));
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then true;

    // no dynamic tearing
    case SimCode.SES_LINEAR(lSystem = lSystem as SimCode.LINEARSYSTEM(), alternativeTearing = NONE()) equation
      i = listLength(lSystem.beqs);
      j = listLength(lSystem.simJac);
      eqs = SimCodeUtil.sortEqSystems(lSystem.residual);
      jeqs = match lSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;

      File.write(file, "\n{\"eqIndex\":");
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
      serializeUses(file,list(match v case SimCodeVar.SIMVAR() then v.name; end match
                              for v in lSystem.vars));
      File.write(file, "],\"equation\":[{\"size\":");
      File.write(file,intString(i));
      if i <> 0 then
        File.write(file,",\"density\":");
        File.writeReal(file,j / (i*i),format="%.2f");
      end if;
      File.write(file,",\"A\":[");
      serializeList1(file,lSystem.simJac,withOperations,serializeLinearCell);
      File.write(file,"],\"b\":[");
      serializeList(file,lSystem.beqs,serializeExp);
      File.write(file,"]}]");

      File.write(file, ",\n\"internal-equations\":[");

      if not listEmpty(eqs) then
        serializeEquation(file,listHead(eqs),section,withOperations,parent=lSystem.index,first=true,assign_type=if lSystem.tornSystem then 1 else 0);
        min(serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=if lSystem.tornSystem then 1 else 0) for e in listRest(eqs));
      end if;
      File.write(file, "\n]");

      File.write(file, ",\n\"jacobian-equations\":[");
      if not listEmpty(jeqs) then
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=lSystem.index,first=true,assign_type=2);
        min(serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=2) for e in listRest(jeqs));
      end if;

      File.write(file, "\n]}");
    then true;

    // dynamic tearing
    case SimCode.SES_LINEAR(lSystem = lSystem as SimCode.LINEARSYSTEM(), alternativeTearing = SOME(atL as SimCode.LINEARSYSTEM())) equation
      // for strict tearing set
      i = listLength(lSystem.beqs);
      j = listLength(lSystem.simJac);

      eqs = SimCodeUtil.sortEqSystems(lSystem.residual);
      if not listEmpty(eqs) then
        serializeEquation(file,listHead(eqs),section,withOperations,parent=lSystem.index,first=true,assign_type=if lSystem.tornSystem then 1 else 0);
        min(serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=if lSystem.tornSystem then 1 else 0) for e in listRest(eqs));
      end if;

      jeqs = match lSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=lSystem.index,first=true,assign_type=2);
        min(serializeEquation(file,e,section,withOperations,parent=lSystem.index,assign_type=2) for e in listRest(jeqs));
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
        File.write(file, "\",\"tag\":\"tornsystem-dynamic\"");
      else
        File.write(file, "\",\"tag\":\"system-dynamic\"");
      end if;

      File.write(file, ",\"display\":\"linear\",\"unknowns\":" + intString(lSystem.nUnknowns) + ",\"defines\":[");
      serializeUses(file,list(match v case SimCodeVar.SIMVAR() then v.name; end match
                              for v in lSystem.vars));
      File.write(file, "],\"equation\":[{\"size\":");
      File.write(file,intString(i));
      if i <> 0 then
        File.write(file,",\"density\":");
        File.writeReal(file,j / (i*i),format="%.2f");
      end if;
      File.write(file,",\"A\":[");
      serializeList1(file,lSystem.simJac,withOperations,serializeLinearCell);
      File.write(file,"],\"b\":[");
      serializeList(file,lSystem.beqs,serializeExp);
      File.write(file,"]}]},");

      // for casual tearing set
      i = listLength(atL.beqs);
      j = listLength(atL.simJac);

      eqs = SimCodeUtil.sortEqSystems(atL.residual);
      if not listEmpty(eqs) then
        serializeEquation(file,listHead(eqs),section,withOperations,parent=atL.index,first=true,assign_type=if atL.tornSystem then 1 else 0);
        min(serializeEquation(file,e,section,withOperations,parent=atL.index,assign_type=if atL.tornSystem then 1 else 0) for e in listRest(eqs));
      end if;

      jeqs = match atL.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=atL.index,first=true,assign_type=2);
        min(serializeEquation(file,e,section,withOperations,parent=atL.index,assign_type=2) for e in listRest(jeqs));
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
      serializeUses(file,list(match v case SimCodeVar.SIMVAR() then v.name; end match
                              for v in atL.vars));
      File.write(file, "],\"equation\":[{\"size\":");
      File.write(file,intString(i));
      if i <> 0 then
        File.write(file,",\"density\":");
        File.writeReal(file,j / (i*i),format="%.2f");
      end if;
      File.write(file,",\"A\":[");
      serializeList1(file,atL.simJac,withOperations,serializeLinearCell);
      File.write(file,"],\"b\":[");
      serializeList(file,atL.beqs,serializeExp);
      File.write(file,"]}]}");
    then true;

    case SimCode.SES_ALGORITHM(statements=stmt::_) algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section + "\",\"tag\":\"algorithm\",\"defines\":[");
      (crefs, crefs2) := Expression.extractUniqueCrefsFromStatmentS(eq.statements);
      serializeUses(file,crefs);
      File.write(file, "],\"uses\":[");
      serializeUses(file,crefs2);
      File.write(file, "],\"equation\":[");
      serializeList(file,eq.statements,serializeStatement);
      File.write(file, "],\"source\":");
      serializeSource(file,Algorithm.getStatementSource(stmt),withOperations);
      File.write(file, "}");
    then true;

    case SimCode.SES_INVERSE_ALGORITHM(statements=stmt::_) algorithm
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section + "\",\"tag\":\"algorithm\",\"defines\":[");
      (crefs, crefs2) := Expression.extractUniqueCrefsFromStatmentS(eq.statements);
      serializeUses(file,crefs);
      File.write(file, "],\"uses\":[");
      serializeUses(file,crefs2);
      File.write(file, "],\"equation\":[");
      serializeList(file,eq.statements,serializeStatement);
      File.write(file, "],\"source\":");
      serializeSource(file,Algorithm.getStatementSource(stmt),withOperations);
      File.write(file, "}");
    then true;

    // no dynamic tearing
    case SimCode.SES_NONLINEAR(nlSystem = nlSystem as SimCode.NONLINEARSYSTEM(), alternativeTearing = NONE()) equation
      eqs = SimCodeUtil.sortEqSystems(nlSystem.eqs);
      jeqs = match nlSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;

      File.write(file, "\n{\"eqIndex\":");
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
      serializeUses(file,nlSystem.crefs);
      File.write(file, "],\"equation\":[[");
      serializeList(file,eqs,serializeEquationIndex);
      File.write(file, "],[");
      serializeList(file,jeqs,serializeEquationIndex);
      File.write(file, "]]");

      File.write(file, ",\n\"internal-equations\":[");

      if not listEmpty(eqs) then
        serializeEquation(file,listHead(eqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=if nlSystem.tornSystem then 1 else 0);
        min(serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=if nlSystem.tornSystem then 1 else 0) for e in listRest(eqs));
      end if;
      File.write(file, "\n]");

      File.write(file, ",\n\"jacobian-equations\":[");
      if not listEmpty(jeqs) then
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=2);
        min(serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=2) for e in listRest(jeqs));
      end if;

      File.write(file, "\n]}");
    then true;

    // dynamic tearing
    case SimCode.SES_NONLINEAR(nlSystem = nlSystem as SimCode.NONLINEARSYSTEM(), alternativeTearing = SOME(atNL as SimCode.NONLINEARSYSTEM())) equation
      // for strict tearing set
      eqs = SimCodeUtil.sortEqSystems(nlSystem.eqs);
      serializeEquation(file,listHead(eqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=if nlSystem.tornSystem then 1 else 0);
      min(serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=if nlSystem.tornSystem then 1 else 0) for e in listRest(eqs));

      jeqs = match nlSystem.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=nlSystem.index,first=true,assign_type=2);
        min(serializeEquation(file,e,section,withOperations,parent=nlSystem.index,assign_type=2) for e in listRest(jeqs));
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
      serializeUses(file,nlSystem.crefs);
      File.write(file, "],\"equation\":[[");
      serializeList(file,eqs,serializeEquationIndex);
      File.write(file, "],[");
      serializeList(file,jeqs,serializeEquationIndex);
      File.write(file, "]]},");

      // for casual tearing set
      eqs = SimCodeUtil.sortEqSystems(atNL.eqs);
      serializeEquation(file,listHead(eqs),section,withOperations,parent=atNL.index,first=true,assign_type=if atNL.tornSystem then 1 else 0);
      min(serializeEquation(file,e,section,withOperations,parent=atNL.index,assign_type=if atNL.tornSystem then 1 else 0) for e in listRest(eqs));

      jeqs = match atNL.jacobianMatrix
        case SOME(SimCode.JAC_MATRIX(columns={SimCode.JAC_COLUMN(columnEqns=jeqs,constantEqns=constantEqns)})) then SimCodeUtil.sortEqSystems(listAppend(jeqs,constantEqns));
        else {};
      end match;
      if not listEmpty(jeqs) then
        File.write(file, ",");
        serializeEquation(file,listHead(jeqs),section,withOperations,parent=atNL.index,first=true,assign_type=2);
        min(serializeEquation(file,e,section,withOperations,parent=atNL.index,assign_type=2) for e in listRest(jeqs));
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
      serializeUses(file,atNL.crefs);
      File.write(file, "],\"equation\":[[");
      serializeList(file,eqs,serializeEquationIndex);
      File.write(file, "],[");
      serializeList(file,jeqs,serializeEquationIndex);
      File.write(file, "]]}");
    then true;

    case SimCode.SES_IFEQUATION() equation
      eqs = listAppend(List.flatten(list(Util.tuple22(e) for e in eq.ifbranches)), eq.elsebranch);
      serializeEquation(file,listHead(eqs),section,withOperations,first=true);
      min(serializeEquation(file,e,section,withOperations) for e in listRest(eqs));
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
    then true;

    case SimCode.SES_MIXED()
      algorithm
        serializeEquation(file,eq.cont,section,withOperations,first=true);
        min(serializeEquation(file,e,section,withOperations) for e in eq.discEqs);
        File.write(file, ",\n{\"eqIndex\":");
        File.writeInt(file, eq.index);
        if parent <> 0 then
          File.write(file, ",\"parent\":");
          File.writeInt(file, parent);
        end if;
        File.write(file, ",\"section\":\"");
        File.write(file, section);
        File.write(file, "\",\"tag\":\"container\",\"display\":\"mixed\",\"defines\":[");
        serializeUses(file,list(SimCodeFunctionUtil.varName(v) for v in eq.discVars));
        File.write(file, "],\"equation\":[");
        serializeEquationIndex(file,eq.cont);
        for e1 in eq.discEqs loop
          File.write(file,",");
          serializeEquationIndex(file,e1);
        end for;
        File.write(file, "]}");
      then true;

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
        _ := match whenOps
          case whenOp as BackendDAE.ASSIGN() equation
            File.write(file, "\",\"tag\":\"when\",\"defines\":[");
            serializeExp(file,whenOp.left);
            File.write(file, "],\"uses\":[");
            serializeUses(file,List.union(eq.conditions,Expression.extractUniqueCrefsFromExpDerPreStart(whenOp.right)));
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.right);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.REINIT() equation
            File.write(file, "\",\"tag\":\"when\",\"defines\":[");
            serializeCref(file,whenOp.stateVar);
            File.write(file, "],\"uses\":[");
            serializeUses(file,List.union(eq.conditions,Expression.extractUniqueCrefsFromExpDerPreStart(whenOp.value)));
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.value);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.ASSERT() equation
            File.write(file, "\",\"tag\":\"when\"");
            File.write(file, ",\"uses\":[");
            crefs = listAppend(Expression.extractUniqueCrefsFromExpDerPreStart(whenOp.condition), Expression.extractUniqueCrefsFromExpDerPreStart(whenOp.message));
            serializeUses(file,List.union(eq.conditions,crefs));
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.message);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.TERMINATE() equation
            File.write(file, "\",\"tag\":\"when\"");
            File.write(file, ",\"uses\":[");
            serializeUses(file,List.union(eq.conditions,Expression.extractUniqueCrefsFromExpDerPreStart(whenOp.message)));
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.message);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
          case whenOp as BackendDAE.NORETCALL() equation
            File.write(file, "\",\"tag\":\"when\"");
            File.write(file, ",\"uses\":[");
            serializeUses(file,List.union(eq.conditions,Expression.extractUniqueCrefsFromExpDerPreStart(whenOp.exp)));
            File.write(file, "],\"equation\":[");
            serializeExp(file,whenOp.exp);
            File.write(file, "],\"source\":");
            serializeSource(file,eq.source,withOperations);
            File.write(file, "}");
          then ();
        end match;
      end for;
      _ := match eq.elseWhen
        local
          SimCode.SimEqSystem e;
        case SOME(e) equation if SimCodeUtil.simEqSystemIndex(e) <>0 then serializeEquation(file,e,section,withOperations); end if; then ();
        else ();
      end match;
    then true;

    case SimCode.SES_FOR_LOOP() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      if parent <> 0 then
        File.write(file, ",\"parent\":");
        File.writeInt(file, parent);
      end if;
      File.write(file, ",\"section\":\"");
      File.write(file, section);
      if (assign_type==1) then
        File.write(file, "\",\"tag\":\"torn\",\"defines\":[\"");
      elseif (assign_type==2) then
        File.write(file, "\",\"tag\":\"jacobian\",\"defines\":[\"");
      else
        File.write(file, "\",\"tag\":\"assign\",\"defines\":[\"");
      end if;
      writeCref(file,eq.cref,escape=JSON);
      File.write(file, "\"],\"uses\":[");
      serializeUses(file,Expression.extractUniqueCrefsFromExpDerPreStart(eq.exp));
      File.write(file, "],\"equation\":[\"");
      File.writeEscape(file,expStr(eq.exp),escape=JSON);
      File.write(file, "\"],\"source\":");
      serializeSource(file,eq.source,withOperations);
      File.write(file, "}");
    then true;

    case SimCode.SES_ALIAS() equation
      File.write(file, "\n{\"eqIndex\":");
      File.writeInt(file, eq.index);
      File.write(file, ",\"tag\":\"alias\",\"equation\":[");
      File.writeInt(file, eq.aliasOf);
      File.write(file, "],\"section\":\"");
      File.write(file, section);
      File.write(file, "\"}");
    then true;

    else equation
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
        Error.addMessage(Error.INTERNAL_ERROR,{"SerializeTaskSystemInfo.serializeLinearCell failed. Expected only SES_RESIDUAL as input."});
      then fail();
  end match;
end serializeLinearCell;

function serializeUses
  input File.File file;
  input list<DAE.ComponentRef> crefs;
algorithm
  _ := match crefs
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest;
    case {} then ();
    case {cr}
      equation
        File.write(file, "\"");
        writeCref(file, cr, escape=JSON);
        File.write(file, "\"");
      then ();
    case cr::rest
      equation
        File.write(file, "\"");
        writeCref(file, cr, escape=JSON);
        File.write(file, "\",");
        serializeUses(file,rest);
      then ();
  end match;
end serializeUses;

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

  partial function FuncType
    input File.File file;
    input ArgType a;
  end FuncType;
algorithm
  _ := match lst
    local
      ArgType a;
      list<ArgType> rest;
    case {} then ();
    case {a}
      equation
        func(file,a);
      then ();
    case a::rest
      equation
        func(file,a);
        File.write(file, ",");
        serializeList(file,rest,func);
      then ();
  end match;
end serializeList;

function serializeList1<ArgType,Extra>
  input File.File file;
  input list<ArgType> lst;
  input Extra extra;
  input FuncType func;

  partial function FuncType
    input File.File file;
    input ArgType a;
    input Extra extra;
  end FuncType;
algorithm
  _ := match lst
    local
      ArgType a;
      list<ArgType> rest;
    case {} then ();
    case {a}
      equation
        func(file,a,extra);
      then ();
    case a::rest
      equation
        func(file,a,extra);
        File.write(file, ",");
        serializeList1(file,rest,extra,func);
      then ();
  end match;
end serializeList1;

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
  File.write(file,",");
  serializeList(file,eqs,serializeEquationIndex);
  File.write(file,"]");
end serializeIfBranch;

function writeEqExpStr
  input File.File file;
  input DAE.EquationExp eqExp;
algorithm
  _ := match eqExp
    case DAE.PARTIAL_EQUATION()
      equation
        File.writeEscape(file,expStr(eqExp.exp),escape=JSON);
      then ();
    case DAE.RESIDUAL_EXP()
      equation
        File.write(file,"0 = ");
        File.writeEscape(file,expStr(eqExp.exp),escape=JSON);
      then ();
    case DAE.EQUALITY_EXPS()
      equation
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
  File.write(file,"{}");
end serializeSource;

annotation(__OpenModelica_Interface="backend");
end SerializeTaskSystemInfo;
