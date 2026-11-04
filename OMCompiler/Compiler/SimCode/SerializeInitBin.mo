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

encapsulated package SerializeInitBin
"Writes <prefix>_init.bin, the model's variables and default experiment read
 by the simulation runtimes, FMUs and OMEdit. The format is described in
 SimulationRuntime/rust/openmodelica_init_file/include/omc_init_file.h."

import SimCode;
import SimCodeVar;

protected
import Absyn;
import AbsynUtil;
import BackendDAE.VarKind;
import ClassInf;
import DAE;
import DAE.{Exp,Type};
import DAEUtil;
import Error;
import Expression;
import ExpressionBasics;
import File;
import List;
import Settings;
import SimCode.{SimulationSettings,VarInfo};
import SimCodeCodegenUtil;
import SimCodeVar.{AliasVariable,Causality,SimVar};
import Types;
import TypesDump;
import UnorderedMap;
import Util;

constant Integer VERSION = 1;
constant Integer SECTION_STRINGS = 1;
constant Integer SECTION_MODEL = 2;
constant Integer SECTION_EXPERIMENT = 3;
constant Integer SECTION_ENUMERATIONS = 4;
constant Integer SECTION_VARIABLES = 5;
constant Integer SECTION_REALS = 6;
constant Integer SECTION_INTEGERS = 7;
constant Integer NUM_SECTIONS = 7;
constant Integer HEADER_SIZE = 16;
constant Integer SECTION_ENTRY_SIZE = 24;
constant Integer MODEL_SIZE = 104;
constant Integer EXPERIMENT_SIZE = 48;
constant Integer ENUMERATION_SIZE = 12;
constant Integer VARIABLE_SIZE = 104;

constant Integer BASE_REAL = 0;
constant Integer BASE_INTEGER = 1;
constant Integer BASE_BOOLEAN = 2;
constant Integer BASE_STRING = 3;
constant Integer BASE_ENUMERATION = 4;
constant Integer BASE_EXTERNAL_OBJECT = 5;

constant Integer FLAG_DISCRETE = 1;
constant Integer FLAG_VALUE_CHANGEABLE = 2;
constant Integer FLAG_PROTECTED = 4;
constant Integer FLAG_ENCRYPTED = 8;
constant Integer FLAG_INIT_NONLINEAR = 16;
constant Integer FLAG_FIXED = 32;
constant Integer FLAG_RELATIVE_QUANTITY = 64;
constant Integer FLAG_FILE_WRITABLE = 128;
constant Integer FLAG_ARRAY = 256;
constant Integer FLAG_USE_NOMINAL = 512;

uniontype Pools
  record POOLS
    UnorderedMap<String, Integer> stringOffsets;
    list<String> strings "reversed";
    Integer stringsSize;
    list<Real> reals "reversed";
    Integer numReals;
    list<Integer> integers "reversed";
    Integer numIntegers;
    String lastFileName;
    Integer lastFileNameOffset;
  end POOLS;
end Pools;

uniontype Values
  record VALUES
    Integer count;
    Integer index;
  end VALUES;
end Values;

constant Values NO_VALUES = VALUES(0, 0);

uniontype VarRecord
  record VAR_RECORD
    Integer name, description, fileName, unit, displayUnit, declaredType, aliasVariable;
    Integer valueReference, inputIndex, classIndex;
    Integer startLine, startColumn, endLine, endColumn;
    Integer classType, baseType, variability, causality, alias, hideResult, flags;
    Integer numDimensions, firstDimension;
    Values start, min, max, nominal;
  end VAR_RECORD;
end VarRecord;

uniontype EnumRecord
  record ENUM_RECORD
    Integer name;
    Integer numLiterals;
    Integer firstLiteral;
  end ENUM_RECORD;
end EnumRecord;

public

function write
  input SimCode.SimCode simCode;
  input String guid;
  input Boolean inMemory = false "for the wasm-jit target, see File.Mode.Memory";
protected
  Pools pools;
  list<VarRecord> vars;
  list<EnumRecord> enums;
  list<Integer> header;
  array<Integer> offsets, sizes, counts;
  Integer offset;
  File.File file = File.File();
  SimulationSettings s;
algorithm
  SOME(s) := simCode.simulationSettingsOpt;
  pools := POOLS(UnorderedMap.new<Integer>(stringHashDjb2, stringEq), {""}, 1, {}, 0, {}, 0, "", 0);
  UnorderedMap.add("", 0, pools.stringOffsets);
  (header, pools) := modelRecord(simCode, guid, pools);
  (enums, pools) := enumerations(SimCodeCodegenUtil.getEnumerationTypes(simCode.modelInfo.vars), pools);
  (vars, pools) := variables(simCode.modelInfo.vars, pools);
  (offset, pools) := internString(s.method, pools);
  (offset, pools) := internString(s.outputFormat, pools);
  (offset, pools) := internString(s.variableFilter, pools);

  counts := arrayCreate(NUM_SECTIONS, 1);
  counts[SECTION_STRINGS] := pools.stringsSize;
  counts[SECTION_ENUMERATIONS] := listLength(enums);
  counts[SECTION_VARIABLES] := listLength(vars);
  counts[SECTION_REALS] := pools.numReals;
  counts[SECTION_INTEGERS] := pools.numIntegers;
  sizes := arrayCreate(NUM_SECTIONS, 0);
  sizes[SECTION_STRINGS] := pools.stringsSize;
  sizes[SECTION_MODEL] := MODEL_SIZE;
  sizes[SECTION_EXPERIMENT] := EXPERIMENT_SIZE;
  sizes[SECTION_ENUMERATIONS] := ENUMERATION_SIZE*listLength(enums);
  sizes[SECTION_VARIABLES] := VARIABLE_SIZE*listLength(vars);
  sizes[SECTION_REALS] := 8*pools.numReals;
  sizes[SECTION_INTEGERS] := 8*pools.numIntegers;
  offsets := arrayCreate(NUM_SECTIONS, 0);
  offset := align8(HEADER_SIZE + SECTION_ENTRY_SIZE*NUM_SECTIONS);
  for i in {SECTION_MODEL, SECTION_EXPERIMENT, SECTION_ENUMERATIONS, SECTION_VARIABLES, SECTION_REALS, SECTION_INTEGERS, SECTION_STRINGS} loop
    offsets[i] := offset;
    offset := align8(offset + sizes[i]);
  end for;

  File.open(file, simCode.fileNamePrefix + "_init.bin", if inMemory then File.Mode.Memory else File.Mode.Write);
  File.write(file, "OMCINIT");
  File.writeBinaryInteger(file, 0, 1);
  File.writeBinaryInteger(file, VERSION, 4);
  File.writeBinaryInteger(file, NUM_SECTIONS, 4);
  for i in 1:NUM_SECTIONS loop
    File.writeBinaryInteger(file, i, 4);
    File.writeBinaryInteger(file, counts[i], 4);
    File.writeBinaryInteger(file, offsets[i], 8);
    File.writeBinaryInteger(file, sizes[i], 8);
  end for;
  pad(file, HEADER_SIZE + SECTION_ENTRY_SIZE*NUM_SECTIONS);

  for v in header loop
    File.writeBinaryInteger(file, v, 4);
  end for;
  writeModelCounts(file, simCode);
  File.writeBinaryReal(file, s.startTime);
  File.writeBinaryReal(file, s.stopTime);
  File.writeBinaryReal(file, s.stepSize);
  File.writeBinaryReal(file, s.tolerance);
  File.writeBinaryInteger(file, UnorderedMap.getOrFail(s.method, pools.stringOffsets), 4);
  File.writeBinaryInteger(file, UnorderedMap.getOrFail(s.outputFormat, pools.stringOffsets), 4);
  File.writeBinaryInteger(file, UnorderedMap.getOrFail(s.variableFilter, pools.stringOffsets), 4);
  File.writeBinaryInteger(file, 0, 4);
  for e in enums loop
    File.writeBinaryInteger(file, e.name, 4);
    File.writeBinaryInteger(file, e.numLiterals, 4);
    File.writeBinaryInteger(file, e.firstLiteral, 4);
  end for;
  pad(file, ENUMERATION_SIZE*listLength(enums));
  for v in vars loop
    writeVariable(file, v);
  end for;
  for r in listReverse(pools.reals) loop
    File.writeBinaryReal(file, r);
  end for;
  for i in listReverse(pools.integers) loop
    File.writeBinaryInteger(file, i, 8);
  end for;
  for str in listReverse(pools.strings) loop
    File.write(file, str);
    File.writeBinaryInteger(file, 0, 1);
  end for;
  pad(file, pools.stringsSize);
end write;

function writeReturnBool
  input SimCode.SimCode simCode;
  input String guid;
  output Boolean success;
algorithm
  try
    write(simCode, guid);
    success := true;
  else
    success := false;
  end try;
end writeReturnBool;

protected

function align8
  input Integer n;
  output Integer m = 8*intDiv(n + 7, 8);
end align8;

function pad
  "Pads a section of the given size to a multiple of 8 bytes."
  input File.File file;
  input Integer size;
algorithm
  for i in size+1:align8(size) loop
    File.writeBinaryInteger(file, 0, 1);
  end for;
end pad;

function internString
  input String str;
  output Integer offset;
  input output Pools pools;
algorithm
  offset := match UnorderedMap.get(str, pools.stringOffsets)
    case SOME(offset) then offset;
    else
      algorithm
        offset := pools.stringsSize;
        UnorderedMap.add(str, offset, pools.stringOffsets);
        pools.strings := str :: pools.strings;
        pools.stringsSize := offset + stringLength(str) + 1;
      then offset;
  end match;
end internString;

function appendString
  "For strings that occur once, e.g. variable names."
  input String str;
  output Integer offset;
  input output Pools pools;
algorithm
  offset := pools.stringsSize;
  pools.strings := str :: pools.strings;
  pools.stringsSize := offset + stringLength(str) + 1;
end appendString;

function internFileName
  "Consecutive variables mostly come from the same file."
  input String fileName;
  output Integer offset;
  input output Pools pools;
algorithm
  if referenceEq(fileName, pools.lastFileName) then
    offset := pools.lastFileNameOffset;
  else
    (offset, pools) := internString(fileName, pools);
    pools.lastFileName := fileName;
    pools.lastFileNameOffset := offset;
  end if;
end internFileName;

function addReals
  input list<Real> values;
  output Values v;
  input output Pools pools;
algorithm
  v := VALUES(listLength(values), pools.numReals);
  pools.reals := List.append_reverse(values, pools.reals);
  pools.numReals := pools.numReals + v.count;
end addReals;

function addIntegers
  input list<Integer> values;
  output Values v;
  input output Pools pools;
algorithm
  v := VALUES(listLength(values), pools.numIntegers);
  pools.integers := List.append_reverse(values, pools.integers);
  pools.numIntegers := pools.numIntegers + v.count;
end addIntegers;

function modelRecord
  input SimCode.SimCode simCode;
  input String guid;
  output list<Integer> fields;
  input output Pools pools;
protected
  list<String> strs;
  list<Integer> offsets = {};
  Integer o;
algorithm
  strs := {AbsynUtil.pathString(simCode.modelInfo.name, usefq=false),
           AbsynUtil.pathString(simCode.modelInfo.name, delimiter="_", usefq=false),
           simCode.modelInfo.description,
           "{" + guid + "}",
           "OpenModelica Compiler " + Settings.getVersionNr(),
           dateTimeString(Util.getCurrentDateTime()),
           simCode.makefileParams.omhome};
  for str in strs loop
    (o, pools) := internString(str, pools);
    offsets := o :: offsets;
  end for;
  fields := listReverse(offsets);
end modelRecord;

function writeModelCounts
  input File.File file;
  input SimCode.SimCode simCode;
protected
  VarInfo vi;
algorithm
  vi := simCode.modelInfo.varInfo;
  File.writeBinaryInteger(file, vi.numStateVars, 4);
  File.writeBinaryInteger(file, vi.numAlgVars + vi.numDiscreteReal + vi.numOptimizeConstraints + vi.numOptimizeFinalConstraints, 4);
  File.writeBinaryInteger(file, vi.numAlgAliasVars, 4);
  File.writeBinaryInteger(file, vi.numParams, 4);
  File.writeBinaryInteger(file, vi.numIntAlgVars, 4);
  File.writeBinaryInteger(file, vi.numIntAliasVars, 4);
  File.writeBinaryInteger(file, vi.numIntParams, 4);
  File.writeBinaryInteger(file, vi.numBoolAlgVars, 4);
  File.writeBinaryInteger(file, vi.numBoolAliasVars, 4);
  File.writeBinaryInteger(file, vi.numBoolParams, 4);
  File.writeBinaryInteger(file, vi.numStringAlgVars, 4);
  File.writeBinaryInteger(file, vi.numStringAliasVars, 4);
  File.writeBinaryInteger(file, vi.numStringParamVars, 4);
  File.writeBinaryInteger(file, vi.numZeroCrossings, 4);
  File.writeBinaryInteger(file, vi.numTimeEvents, 4);
  File.writeBinaryInteger(file, vi.numInVars, 4);
  File.writeBinaryInteger(file, vi.numOutVars, 4);
  File.writeBinaryInteger(file, vi.numExternalObjects, 4);
  File.writeBinaryInteger(file, listLength(simCode.modelInfo.functions), 4);
end writeModelCounts;

function dateTimeString "YYYY-MM-DDThh:mm:ssZ"
  input Util.DateTime dt;
  output String str = intString(dt.year) + "-" + pad2(dt.mon) + "-" + pad2(dt.mday) +
                      "T" + pad2(dt.hour) + ":" + pad2(dt.min) + ":" + pad2(dt.sec) + "Z";
end dateTimeString;

function pad2
  input Integer i;
  output String str = if i < 10 then "0" + intString(i) else intString(i);
end pad2;

function enumerations
  input list<SimVar> enumerationVars "one variable per enumeration type";
  output list<EnumRecord> enums = {};
  input output Pools pools;
protected
  Absyn.Path path;
  list<String> names;
  list<Integer> literals;
  Integer name, o;
  Values v;
algorithm
  for var in enumerationVars loop
    Type.T_ENUMERATION(path = path, names = names) := Types.arrayElementType(var.type_);
    (name, pools) := internString(AbsynUtil.pathString(path, usefq=false), pools);
    literals := {};
    for n in names loop
      (o, pools) := internString(n, pools);
      literals := o :: literals;
    end for;
    (v, pools) := addIntegers(listReverse(literals), pools);
    enums := ENUM_RECORD(name, v.count, v.index) :: enums;
  end for;
  enums := listReverse(enums);
end enumerations;

function variables
  input SimCodeVar.SimVars vars;
  output list<VarRecord> records = {};
  input output Pools pools;
protected
  Integer vr = 1000, ix = 0;
  UnorderedMap<DAE.Exp, Integer> dims;
algorithm
  dims := dimensionValueReferences(vars, vr);
  (vr, _, records, pools) := addVariables(vars.stateVars, 0, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.derivativeVars, 1, vr, 0, dims, records, pools);
  (vr, ix, records, pools) := addVariables(vars.algVars, 2, vr, ix, dims, records, pools);
  (vr, ix, records, pools) := addVariables(vars.discreteAlgVars, 2, vr, ix, dims, records, pools);
  (vr, ix, records, pools) := addVariables(vars.realOptimizeConstraintsVars, 2, vr, ix, dims, records, pools);
  (vr, ix, records, pools) := addVariables(vars.realOptimizeFinalConstraintsVars, 2, vr, ix, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.paramVars, 3, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.aliasVars, 4, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.intAlgVars, 5, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.intParamVars, 6, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.intAliasVars, 7, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.boolAlgVars, 8, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.boolParamVars, 9, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.boolAliasVars, 10, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.stringAlgVars, 11, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.stringParamVars, 12, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.stringAliasVars, 13, vr, 0, dims, records, pools);
  (vr, _, records, pools) := addVariables(vars.sensitivityVars, 14, vr, 0, dims, records, pools);
  records := listReverse(records);
end variables;

function dimensionValueReferences
  "The value references the Integer parameters get in variables, keyed by the
   dimension they stand for: the parameter itself, and for a size parameter
   $DIM_k of a derived dimension (N-1) its start expression."
  input SimCodeVar.SimVars vars;
  input Integer firstValueReference;
  output UnorderedMap<DAE.Exp, Integer> dims = UnorderedMap.new<Integer>(ExpressionBasics.hashExp, ExpressionBasics.expEqual);
protected
  Integer vr;
algorithm
  vr := firstValueReference + listLength(vars.stateVars) + listLength(vars.derivativeVars)
    + listLength(vars.algVars) + listLength(vars.discreteAlgVars) + listLength(vars.realOptimizeConstraintsVars)
    + listLength(vars.realOptimizeFinalConstraintsVars) + listLength(vars.paramVars) + listLength(vars.aliasVars)
    + listLength(vars.intAlgVars);
  for var in vars.intParamVars loop
    UnorderedMap.add(DAE.CREF(var.name, var.type_), vr, dims);
    if SimCodeCodegenUtil.isDimensionParameter(var) then
      UnorderedMap.add(Util.getOption(var.initialValue), vr, dims);
    end if;
    vr := vr + 1;
  end for;
end dimensionValueReferences;

function addVariables
  input list<SimVar> vars;
  input Integer classType;
  input output Integer valueReference;
  input output Integer classIndex;
  input UnorderedMap<DAE.Exp, Integer> dims;
  input output list<VarRecord> records;
  input output Pools pools;
protected
  VarRecord r;
algorithm
  for var in vars loop
    (r, pools) := variable(var, classType, valueReference, classIndex, dims, pools);
    records := r :: records;
    classIndex := classIndex + 1;
    valueReference := valueReference + 1;
  end for;
end addVariables;

function variable
  input SimVar var;
  input Integer classType;
  input Integer valueReference;
  input Integer classIndex;
  input UnorderedMap<DAE.Exp, Integer> dims;
  output VarRecord r;
  input output Pools pools;
protected
  SourceInfo info = var.source.info;
  Integer name, description, fileName, unit, displayUnit, declaredType, aliasVariable;
  Integer alias, baseType, flags, numDimensions, firstDimension;
  Values start, min, max, nominal;
algorithm
  (name, pools) := appendString(crefString(var.name), pools);
  (description, pools) := internString(var.comment, pools);
  (fileName, pools) := internFileName(info.fileName, pools);
  (unit, pools) := internString(var.unit, pools);
  (displayUnit, pools) := internString(var.displayUnit, pools);
  (aliasVariable, alias, pools) := aliasInfo(var, pools);
  (baseType, declaredType, pools) := typeInfo(var, pools);
  (numDimensions, firstDimension, pools) := dimensions(var, dims, pools);
  (start, pools) := values(var.initialValue, baseType, pools);
  if baseType == BASE_REAL then
    (min, pools) := values(var.minValue, baseType, pools);
    (max, pools) := values(var.maxValue, baseType, pools);
    (nominal, pools) := values(var.nominalValue, baseType, pools);
  elseif baseType == BASE_INTEGER then
    (min, pools) := values(var.minValue, baseType, pools);
    (max, pools) := values(var.maxValue, baseType, pools);
    nominal := NO_VALUES;
  else
    min := NO_VALUES;
    max := NO_VALUES;
    nominal := NO_VALUES;
  end if;
  flags := flag(var.isDiscrete, FLAG_DISCRETE) + flag(var.isValueChangeable, FLAG_VALUE_CHANGEABLE)
         + flag(var.isProtected, FLAG_PROTECTED) + flag(var.isEncrypted, FLAG_ENCRYPTED)
         + flag(var.initNonlinear, FLAG_INIT_NONLINEAR)
         + flag(var.isFixed and baseType <> BASE_EXTERNAL_OBJECT, FLAG_FIXED)
         + flag(var.relativeQuantity and baseType == BASE_REAL, FLAG_RELATIVE_QUANTITY)
         + flag(not info.isReadOnly, FLAG_FILE_WRITABLE)
         + flag(DAEUtil.expTypeArray(var.type_), FLAG_ARRAY)
         + flag(isSome(var.nominalValue) and baseType == BASE_REAL, FLAG_USE_NOMINAL);
  r := VAR_RECORD(name, description, fileName, unit, displayUnit, declaredType, aliasVariable,
                  valueReference, SimCodeCodegenUtil.getInputIndex(var), classIndex,
                  info.lineNumberStart, info.columnNumberStart, info.lineNumberEnd, info.columnNumberEnd,
                  classType, baseType, variability(var.varKind), causality(var.causality), alias,
                  hideResult(var.hideResult), flags, numDimensions, firstDimension,
                  start, min, max, nominal);
end variable;

function flag
  input Boolean b;
  input Integer bit;
  output Integer i = if b then bit else 0;
end flag;

function hideResult
  input Option<Boolean> hide;
  output Integer i;
algorithm
  i := match hide
    case SOME(false) then 1;
    case SOME(true) then 2;
    else 0;
  end match;
end hideResult;

function variability
  input VarKind varKind;
  output Integer i;
algorithm
  i := match varKind
    case VarKind.DISCRETE() then 1;
    case VarKind.PARAM() then 2;
    case VarKind.CONST() then 3;
    else 0;
  end match;
end variability;

function causality
  input Option<Causality> c;
  output Integer i;
algorithm
  i := match c
    case SOME(Causality.NONECAUS()) then 1;
    case SOME(Causality.OUTPUT()) then 2;
    case SOME(Causality.INPUT()) then 3;
    case SOME(Causality.PARAMETER()) then 4;
    case SOME(Causality.CALCULATED_PARAMETER()) then 5;
    else 0;
  end match;
end causality;

function aliasInfo
  input SimVar var;
  output Integer aliasVariable = 0;
  output Integer alias = 0;
  input output Pools pools;
protected
  DAE.ComponentRef target;
algorithm
  (alias, target) := match var.aliasvar
    local
      DAE.ComponentRef name;
    case AliasVariable.ALIAS(varName = name) then (1, name);
    case AliasVariable.NEGATEDALIAS(varName = name) then (2, name);
    else (0, var.name);
  end match;
  if alias <> 0 then
    (aliasVariable, pools) := appendString(crefString(target), pools);
  end if;
end aliasInfo;

function typeInfo
  input SimVar var;
  output Integer baseType;
  output Integer declaredType = 0;
  input output Pools pools;
algorithm
  baseType := match Types.arrayElementType(var.type_)
    local
      Absyn.Path path;
    case Type.T_REAL() then BASE_REAL;
    case Type.T_INTEGER() then BASE_INTEGER;
    case Type.T_BOOL() then BASE_BOOLEAN;
    case Type.T_STRING() then BASE_STRING;
    case Type.T_ENUMERATION(path = path)
      algorithm
        (declaredType, pools) := internString(AbsynUtil.pathString(path, usefq=false), pools);
      then BASE_ENUMERATION;
    case Type.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = path))
      algorithm
        (declaredType, pools) := internString(AbsynUtil.pathString(path), pools);
      then BASE_EXTERNAL_OBJECT;
    else
      algorithm
        Error.addInternalError(getInstanceName() + ": " + TypesDump.unparseType(var.type_), sourceInfo());
      then fail();
  end match;
end typeInfo;

function dimensions
  "Each dimension is two entries in the integer pool: its size, or -1, and the
   value reference of the Integer parameter that gives it, or -1."
  input SimVar var;
  input UnorderedMap<DAE.Exp, Integer> dims;
  output Integer numDimensions = 0;
  output Integer firstDimension;
  input output Pools pools;
protected
  list<Integer> entries = {};
  Values v;
algorithm
  for dim in Expression.arrayDimension(var.type_) loop
    entries := match dim
      local
        Integer vr;
      case DAE.DIM_EXP() guard not Expression.isConst(dim.exp)
        algorithm
          try
            SOME(vr) := UnorderedMap.get(dim.exp, dims);
          else
            Error.addCompilerError("The dimension " + ExpressionBasics.printExpStr(dim.exp) + " of " + crefString(var.name)
              + " is neither an Integer parameter nor has a size parameter. It is not supported for resizable arrays (--resizableArrays).");
            fail();
          end try;
        then vr :: -1 :: entries;
      else -1 :: Expression.dimensionSize(dim) :: entries;
    end match;
    numDimensions := numDimensions + 1;
  end for;
  (v, pools) := addIntegers(listReverse(entries), pools);
  firstDimension := v.index;
end dimensions;

function values
  input Option<Exp> exp;
  input Integer baseType;
  output Values v = NO_VALUES;
  input output Pools pools;
protected
  list<Exp> elements;
  list<Integer> strs = {};
  Integer o;
algorithm
  if isNone(exp) then
    return;
  end if;
  try
    elements := literalElements(Util.getOption(exp));
    if baseType == BASE_REAL then
      (v, pools) := addReals(list(realValue(e) for e in elements), pools);
    elseif baseType == BASE_STRING then
      for e in elements loop
        (o, pools) := internString(stringValue(e), pools);
        strs := o :: strs;
      end for;
      (v, pools) := addIntegers(listReverse(strs), pools);
    else
      (v, pools) := addIntegers(list(integerValue(e) for e in elements), pools);
    end if;
  else
  end try;
end values;

function literalElements
  "The values of a literal start, min, max or nominal: one for a scalar or a
   value broadcast to all elements of an array, else one per element."
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

function stringValue
  input Exp exp;
  output String s;
algorithm
  Exp.SCONST(string = s) := exp;
end stringValue;

function crefString
  "The name as the result file and -override spell it, e.g. der(a.b[1])."
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

function writeVariable
  input File.File file;
  input VarRecord v;
algorithm
  File.writeBinaryInteger(file, v.name, 4);
  File.writeBinaryInteger(file, v.description, 4);
  File.writeBinaryInteger(file, v.fileName, 4);
  File.writeBinaryInteger(file, v.unit, 4);
  File.writeBinaryInteger(file, v.displayUnit, 4);
  File.writeBinaryInteger(file, v.declaredType, 4);
  File.writeBinaryInteger(file, v.aliasVariable, 4);
  File.writeBinaryInteger(file, v.valueReference, 4);
  File.writeBinaryInteger(file, v.inputIndex, 4);
  File.writeBinaryInteger(file, v.classIndex, 4);
  File.writeBinaryInteger(file, v.startLine, 4);
  File.writeBinaryInteger(file, v.startColumn, 4);
  File.writeBinaryInteger(file, v.endLine, 4);
  File.writeBinaryInteger(file, v.endColumn, 4);
  File.writeBinaryInteger(file, v.classType, 1);
  File.writeBinaryInteger(file, v.baseType, 1);
  File.writeBinaryInteger(file, v.variability, 1);
  File.writeBinaryInteger(file, v.causality, 1);
  File.writeBinaryInteger(file, v.alias, 1);
  File.writeBinaryInteger(file, v.hideResult, 1);
  File.writeBinaryInteger(file, v.flags, 2);
  File.writeBinaryInteger(file, v.numDimensions, 4);
  File.writeBinaryInteger(file, v.firstDimension, 4);
  writeValues(file, v.start);
  writeValues(file, v.min);
  writeValues(file, v.max);
  writeValues(file, v.nominal);
end writeVariable;

function writeValues
  input File.File file;
  input Values v;
algorithm
  File.writeBinaryInteger(file, v.count, 4);
  File.writeBinaryInteger(file, v.index, 4);
end writeValues;

annotation(__OpenModelica_Interface="backend_tools");
end SerializeInitBin;
