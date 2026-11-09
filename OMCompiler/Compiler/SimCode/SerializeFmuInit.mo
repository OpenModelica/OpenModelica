/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SerializeFmuInit
"Writes resources/<prefix>_init.bin of a C FMU 2.0 or 3.0: the default
 experiment and the info and attributes of the variables. The format is
 described in SimulationRuntime/c/util/omc_fmu_init.h."

import SimCode;
import SimCodeVar;

protected
import DAE;
import DAE.{Exp,Type};
import Expression;
import ExpressionBasics;
import File;
import List;
import SimCode.SimulationSettings;
import SimCodeVar.SimVar;
import Types;
import UnorderedMap;
import Util;

constant Integer VERSION = 1;
constant Integer PARAM_DEPS_VERSION = 1;

type Kind = enumeration(REAL, INTEGER, BOOLEAN, STRING);

public

function write
  input SimCode.SimCode simCode;
  input String fileName;
protected
  SimCodeVar.SimVars vars = simCode.modelInfo.vars;
  SimulationSettings s;
  list<tuple<Kind, list<SimVar>>> arrays;
  UnorderedMap<String, Integer> fileIndex = UnorderedMap.new<Integer>(stringHashDjb2, stringEq);
  list<String> fileNames = {};
  Integer numFiles = 0;
  File.File file = File.File();
algorithm
  SOME(s) := simCode.simulationSettingsOpt;
  arrays := {(Kind.REAL, List.flatten({vars.stateVars, vars.derivativeVars, vars.algVars, vars.discreteAlgVars,
                                      vars.realOptimizeConstraintsVars, vars.realOptimizeFinalConstraintsVars})),
             (Kind.REAL, vars.paramVars), (Kind.INTEGER, vars.intAlgVars), (Kind.INTEGER, vars.intParamVars),
             (Kind.BOOLEAN, vars.boolAlgVars), (Kind.BOOLEAN, vars.boolParamVars),
             (Kind.STRING, vars.stringAlgVars), (Kind.STRING, vars.stringParamVars)};
  for a in arrays loop
    for var in Util.tuple22(a) loop
      if not UnorderedMap.contains(var.source.info.fileName, fileIndex) then
        UnorderedMap.add(var.source.info.fileName, numFiles, fileIndex);
        fileNames := var.source.info.fileName :: fileNames;
        numFiles := numFiles + 1;
      end if;
    end for;
  end for;

  File.open(file, fileName, File.Mode.Write);
  File.write(file, "OMCFMUI");
  File.writeBinaryInteger(file, 0, 1);
  File.writeBinaryInteger(file, VERSION, 4);
  for a in arrays loop
    File.writeBinaryInteger(file, listLength(Util.tuple22(a)), 4);
  end for;
  File.writeBinaryReal(file, s.startTime);
  File.writeBinaryReal(file, s.stopTime);
  File.writeBinaryReal(file, s.stepSize);
  File.writeBinaryReal(file, s.tolerance);
  writeString(file, s.method);
  writeUnsigned(file, numFiles);
  for f in listReverse(fileNames) loop
    writeString(file, f);
  end for;
  for a in arrays loop
    for var in Util.tuple22(a) loop
      writeVariable(file, Util.tuple21(a), var, UnorderedMap.getOrFail(var.source.info.fileName, fileIndex));
    end for;
  end for;
end write;

function writeParamDeps
  "Writes resources/<prefix>_paramdeps.bin, see SimCode.ParamDeps. The format
   is described in SimulationRuntime/c/util/omc_fmu_paramdeps.h."
  input SimCode.ParamDeps deps;
  input String fileName;
protected
  File.File file = File.File();
algorithm
  File.open(file, fileName, File.Mode.Write);
  File.write(file, "OMCFMUP");
  File.writeBinaryInteger(file, 0, 1);
  File.writeBinaryInteger(file, PARAM_DEPS_VERSION, 4);
  File.writeBinaryInteger(file, if deps.checked then 1 else 0, 1);
  writeUnsigned(file, listLength(deps.eqs));
  for eq in deps.eqs loop
    File.writeBinaryInteger(file, if isSome(eq.eq) then 1 else 0, 1);
    writeUnsigned(file, listLength(eq.uses));
    for s in eq.uses loop
      writeUnsigned(file, s);
    end for;
    writeUnsigned(file, listLength(eq.defines));
    for s in eq.defines loop
      writeUnsigned(file, s);
    end for;
  end for;
  writeUnsigned(file, listLength(deps.settable));
  for t in deps.settable loop
    writeUnsigned(file, Util.tuple21(t));
    File.writeBinaryInteger(file, Util.tuple22(t), 1);
  end for;
end writeParamDeps;

protected

function writeVariable
  input File.File file;
  input Kind kind;
  input SimVar var;
  input Integer fileIndex;
protected
  SourceInfo info = var.source.info;
  Type ty = Types.arrayElementType(var.type_);
  list<Integer> dims = {};
  list<Exp> start, min = {}, max = {}, nominal = {};
algorithm
  if Types.isArray(var.type_) then
    dims := list(stringInt(d) for d in var.numArrayElement);
  end if;
  start := literalValues(var.initialValue);
  _ := match ty
    case DAE.T_REAL()
      algorithm
        min := literalValues(var.minValue);
        max := literalValues(var.maxValue);
        nominal := literalValues(var.nominalValue);
      then ();
    case DAE.T_INTEGER()
      algorithm
        min := literalValues(var.minValue);
        max := literalValues(var.maxValue);
      then ();
    case DAE.T_ENUMERATION()
      algorithm
        min := if isSome(var.minValue) then literalValues(var.minValue) else {DAE.ICONST(1)};
        max := if isSome(var.maxValue) then literalValues(var.maxValue) else {DAE.ICONST(listLength(ty.names))};
      then ();
    else ();
  end match;

  File.writeBinaryInteger(file, flag(info.isReadOnly, 1) + flag(var.isFixed, 2)
    + flag(kind == Kind.REAL and isSome(var.nominalValue), 4) + flag(not listEmpty(dims), 8)
    + flag(not listEmpty(start), 16) + flag(not listEmpty(min), 32) + flag(not listEmpty(max), 64)
    + flag(not listEmpty(nominal), 128), 1);
  writeString(file, crefString(var.name));
  writeUnsigned(file, fileIndex);
  writeSigned(file, info.lineNumberStart);
  writeSigned(file, info.columnNumberStart);
  writeSigned(file, info.lineNumberEnd);
  writeSigned(file, info.columnNumberEnd);
  if not listEmpty(dims) then
    writeUnsigned(file, listLength(dims));
    for d in dims loop
      writeSigned(file, d);
    end for;
  end if;
  for values in {start, min, max, nominal} loop
    if not listEmpty(values) then
      writeUnsigned(file, listLength(values));
      for e in values loop
        writeValue(file, kind, e);
      end for;
    end if;
  end for;
end writeVariable;

function writeValue
  input File.File file;
  input Kind kind;
  input Exp e;
protected
  String str;
algorithm
  if kind == Kind.REAL then
    File.writeBinaryReal(file, realValue(e));
  elseif kind == Kind.INTEGER then
    writeSigned(file, integerValue(e));
  elseif kind == Kind.BOOLEAN then
    File.writeBinaryInteger(file, integerValue(e), 1);
  else
    Exp.SCONST(string = str) := e;
    writeString(file, str);
  end if;
end writeValue;

function literalValues
  "A literal start, min, max or nominal: one value for a scalar or a value of
   all elements of an array, else one per element. Empty if not a literal."
  input Option<Exp> exp;
  output list<Exp> values;
algorithm
  values := match exp
    local
      Exp e;
    case SOME(e)
      algorithm
        try
          values := literalElements(e);
        else
          values := {};
        end try;
      then values;
    else {};
  end match;
end literalValues;

function flag
  input Boolean b;
  input Integer bit;
  output Integer i = if b then bit else 0;
end flag;

function writeUnsigned
  "LEB128."
  input File.File file;
  input Integer n;
protected
  Integer v = n;
algorithm
  while v >= 128 loop
    File.writeBinaryInteger(file, 128 + intMod(v, 128), 1);
    v := intDiv(v, 128);
  end while;
  File.writeBinaryInteger(file, v, 1);
end writeUnsigned;

function writeSigned
  "Bit 0 of the first byte is the sign, its bits 1-6 the low bits of n (or of
   -n-1 for a negative n), bit 7 that more follow, as LEB128."
  input File.File file;
  input Integer n;
protected
  Integer m = if n >= 0 then n else -(n + 1);
  Integer first = 2 * intMod(m, 64) + (if n >= 0 then 0 else 1);
algorithm
  if m >= 64 then
    File.writeBinaryInteger(file, 128 + first, 1);
    writeUnsigned(file, intDiv(m, 64));
  else
    File.writeBinaryInteger(file, first, 1);
  end if;
end writeSigned;

function writeString
  input File.File file;
  input String str;
algorithm
  writeUnsigned(file, stringLength(str));
  File.write(file, str);
end writeString;

function literalElements
  input Exp exp;
  output list<Exp> elements;
algorithm
  elements := match exp
    local
      Integer n;
    case Exp.ICONST() then {exp};
    case Exp.RCONST() then {exp};
    case Exp.SCONST() then {exp};
    case Exp.BCONST() then {exp};
    case Exp.ENUM_LITERAL() then {exp};
    case Exp.ARRAY() guard Expression.isSimpleLiteralValue(exp, true)
      then List.flatten(list(literalElements(e) for e in exp.array));
    case Exp.REDUCTION() guard isBroadcastValue(exp.expr) then literalElements(exp.expr);
    case Exp.REDUCTION()
      algorithm
        n := List.fold(list(Expression.dimensionSize(d) for d in List.firstN(Expression.arrayDimension(exp.reductionInfo.exprType), listLength(exp.iterators))), intMul, 1);
      then List.flatten(List.fill(literalElements(exp.expr), n));
  end match;
end literalElements;

function isBroadcastValue
  input Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case Exp.ARRAY() then false;
    case Exp.REDUCTION() then isBroadcastValue(exp.expr);
    else true;
  end match;
end isBroadcastValue;

function realValue
  input Exp exp;
  output Real r;
algorithm
  r := match exp
    case Exp.RCONST() then exp.real;
    case Exp.ICONST() then intReal(exp.integer);
    case Exp.ENUM_LITERAL() then intReal(exp.index);
    case Exp.BCONST() then if exp.bool then 1.0 else 0.0;
  end match;
end realValue;

function integerValue
  input Exp exp;
  output Integer i;
algorithm
  i := match exp
    case Exp.ICONST() then exp.integer;
    case Exp.ENUM_LITERAL() then exp.index;
    case Exp.BCONST() then if exp.bool then 1 else 0;
    case Exp.RCONST() then realInt(exp.real);
  end match;
end integerValue;

function crefString
  "The name as the result file spells it, e.g. der(a.b[1])."
  input DAE.ComponentRef cref;
  output String str = stringAppendList(listReverse(crefParts(cref, {})));
end crefString;

function crefParts
  "The pieces of crefString, reversed."
  input DAE.ComponentRef cref;
  input output list<String> parts;
algorithm
  parts := match cref
    case DAE.CREF_IDENT() then subscriptsParts(cref.subscriptLst, cref.ident :: parts);
    case DAE.CREF_QUAL(ident = DAE.derivativeNamePrefix) then ")" :: crefParts(cref.componentRef, "der(" :: parts);
    case DAE.CREF_QUAL(ident = DAE.previousNamePrefix) then ")" :: crefParts(cref.componentRef, "previous(" :: parts);
    case DAE.CREF_QUAL() then crefParts(cref.componentRef, "." :: subscriptsParts(cref.subscriptLst, cref.ident :: parts));
  end match;
end crefParts;

function subscriptsParts
  input list<DAE.Subscript> subs;
  input output list<String> parts;
protected
  Boolean first = true;
algorithm
  if listEmpty(subs) then
    return;
  end if;
  parts := "[" :: parts;
  for s in subs loop
    if not first then
      parts := "," :: parts;
    end if;
    first := false;
    parts := subscriptString(s) :: parts;
  end for;
  parts := "]" :: parts;
end subscriptsParts;

function subscriptString
  input DAE.Subscript sub;
  output String str;
algorithm
  str := match sub
    local
      Integer i;
    case DAE.WHOLEDIM() then ":";
    case DAE.SLICE(DAE.ICONST(i)) then intString(i);
    case DAE.INDEX(DAE.ICONST(i)) then intString(i);
    case DAE.WHOLE_NONEXP(DAE.ICONST(i)) then intString(i);
    case DAE.SLICE() then ExpressionBasics.printExpStr(sub.exp);
    case DAE.INDEX() then ExpressionBasics.printExpStr(sub.exp);
    case DAE.WHOLE_NONEXP() then ExpressionBasics.printExpStr(sub.exp);
  end match;
end subscriptString;

annotation(__OpenModelica_Interface="backend_tools");
end SerializeFmuInit;
