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

encapsulated package NSimVar
"file:        NSimVar.mo
 package:     NSimVar
 description: This file contains the data types and functions for variables
              in simulation code phase.
"
protected
  // OF imports
  import DAE;
  import SCode;

  // NF imports
  import NFBackendExtension.{BackendInfo, VariableAttributes, VariableKind};
  import Binding = NFBinding;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Operator = NFOperator;
  import Prefixes = NFPrefixes;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;
  import MetaModelica.Dangerous.listReverseInPlace;
  import NBVariable.VariablePointers;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // Backend imports
  import BVariable = NBVariable;
  import NBEquation.Equation;
  import NBEvents.{EventInfo, Condition};
  import NBPartition.Partition;
  import Slice = NBSlice;
  import StrongComponent = NBStrongComponent;

  // Old Simcode imports
  import OldSimCode = SimCode;
  import OldSimCodeVar = SimCodeVar;

  // SimCode imports
  import SimCode = NSimCode;
  import NSimCode.SimCodeIndices;

  // Util imports
  import Config;
  import Error;
  import Pointer;
  import StringUtil;
  import Util;

public
  type ConvertEntry = tuple<SimVar, OldSimCodeVar.SimVar>;
  type ConvertMemo = UnorderedMap<ComponentRef, ConvertEntry> "SimVar -> old SimVar conversions already made";

  uniontype SimVar "Information about a variable in a Modelica model."
    record SIMVAR
      ComponentRef name;
      VariableKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Integer index;
      Option<Expression> min;
      Option<Expression> max;
      Option<Expression> start;
      Option<Expression> nominal;
      Boolean isFixed;
      Type type_;
      Boolean isDiscrete;
      Option<ComponentRef> arrayCref "the name of the array if this variable is the first in that array";
      Alias aliasvar;
      SourceInfo info;
      Option<Causality> causality;
      Option<Integer> variable_index "valueReference";
      Option<Integer> fmi_index "index of variable in modelDescription.xml";
      list<Expression> numArrayElement;
      Boolean isValueChangeable;
      Boolean isProtected;
      Boolean hideResult;
      Boolean isEncrypted;
      Option<array<Integer>> inputIndex;
      Option<String> matrixName "if the varibale is a jacobian var, this is the corresponding matrix";
      Option<Variability> variability "FMI-2.0 variabilty attribute";
      Option<Initial> initial_ "FMI-2.0 initial attribute";
      Option<ComponentRef> exportVar "variables will only be exported to the modelDescription.xml if this attribute is SOME(cref) and this cref is only used in ModelDescription.xml for FMI-2.0 export";
      Boolean isConnectorFlow "true if the variable is a flow connector member (FMI 3.0 terminal variableKind inflow/outflow)";
    end SIMVAR;

    function toString
      input SimVar var;
      input output String str = "";
    algorithm
      str := str + "(" + intString(var.index) + ")" + VariableKind.toString(var.varKind)
        + " (" + intString(SimVar.size(var)) + ") " + Type.toString(var.type_) + " " + ComponentRef.toString(var.name);
      if isSome(var.start) then
        str := str + " = " + Expression.toString(Util.getOption(var.start));
      end if;
    end toString;

    function listToString
      input list<SimVar> var_lst;
      input output String str = "";
      input Boolean printAlias = false;
    algorithm
      if not listEmpty(var_lst) then
        str := StringUtil.headline_4(str + " (" + intString(listLength(var_lst)) + ")");
        for var in var_lst loop
          str := str + toString(var, "  ");
          str := if printAlias then str + " " + Alias.toString(var.aliasvar) + "\n" else str + "\n";
        end for;
        str := str + "\n";
      else
        str := "";
      end if;
    end listToString;

    function create
      input Variable var;
      output SimVar simVar;
      input Integer uniqueIndex;
      input Integer typeIndex;
      input Alias alias = Alias.NO_ALIAS();
    algorithm
      simVar := match var
        local
          VariableKind varKind;
          String comment, unit, displayUnit;
          Option<Expression> min;
          Option<Expression> max;
          Option<Expression> start;
          Option<Expression> nominal;
          Boolean isFixed, isDiscrete, isProtected, isValueChangeable;
          Causality causality;
          SimVar result;

        case Variable.VARIABLE() algorithm
          comment := parseComment(var.comment);
          (varKind, unit, displayUnit, min, max, start, nominal, isFixed, isDiscrete, isProtected)
          := parseAttributes(var.backendinfo);
          // for parameters the binding supersedes the start value if it exists and is constant
          // ToDo: also for other cases? (constant, struct param ...)
          (start, isValueChangeable, causality) := parseBinding(start, var);
          result := SIMVAR(
            name                = var.name,
            varKind             = varKind,
            comment             = comment,
            unit                = unit,
            displayUnit         = displayUnit,
            index               = typeIndex,
            min                 = min,
            max                 = max,
            start               = start,
            nominal             = nominal,
            isFixed             = isFixed,
            type_               = var.ty,
            isDiscrete          = isDiscrete,
            arrayCref           = ComponentRef.getArrayCrefOpt(var.name),
            aliasvar            = alias,
            info                = var.info,
            causality           = SOME(causality),
            variable_index      = SOME(uniqueIndex),
            fmi_index           = SOME(typeIndex),
            // dimension sizes (row-major); empty for scalars. Used for FMI array variables.
            numArrayElement     = list(Dimension.sizeExp(dim) for dim in Type.arrayDims(var.ty)),
            isValueChangeable   = isValueChangeable,
            isProtected         = isProtected,
            hideResult          = var.backendinfo.annotations.hideResult,
            isEncrypted         = NFVariable.isEncrypted(var),
            inputIndex          = NONE(),
            matrixName          = NONE(),
            variability         = NONE(),
            initial_            = NONE(),
            exportVar           = SOME(var.name),
            isConnectorFlow     = Variable.isFlow(var)
          );
        then result;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable " + ComponentRef.toString(var.name) + "."});
        then fail();

      end match;
    end create;

    function traverseCreate
      input output Variable var;
      input Pointer<list<SimVar>> acc;
      input Pointer<SimCode.SimCodeIndices> indices_ptr;
      input VarType varType = VarType.SIMULATION;
    protected
      SimCode.SimCodeIndices simCodeIndices = Pointer.access(indices_ptr);
    algorithm
      () := match varType

        case VarType.SIMULATION algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.realVarIndex) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.realVarIndex := simCodeIndices.realVarIndex + 1;
        then ();

        case VarType.PARAMETER algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.realParamIndex) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.realParamIndex := simCodeIndices.realParamIndex + 1;
        then ();

        case VarType.ALIAS algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.realAliasIndex, Alias.fromBinding(var.binding)) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.realAliasIndex := simCodeIndices.realAliasIndex + 1;
        then ();

        case VarType.RESIDUAL algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.residualIndex) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.residualIndex := simCodeIndices.residualIndex + 1;
        then ();

        case VarType.EXTERNAL_OBJECT algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.extObjIndex) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.extObjIndex := simCodeIndices.extObjIndex + 1;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable " + ComponentRef.toString(var.name) + "."});
        then fail();

      end match;
      Pointer.update(indices_ptr, simCodeIndices);
    end traverseCreate;

    function createList
      "SimVars for scalar variables in list order, with running indices."
      input list<Pointer<Variable>> vars;
      input VarType varType;
      output list<SimVar> simVars = {};
      input output SimCode.SimCodeIndices indices;
    protected
      Integer uniq = indices.uniqueIndex;
      Integer idx = getTypeIndex(indices, varType);
      Variable var;
    algorithm
      for var_ptr in vars loop
        var := Pointer.access(var_ptr);
        simVars := create(var, uniq, idx, if varType == VarType.ALIAS then Alias.fromBinding(var.binding) else Alias.NO_ALIAS()) :: simVars;
        uniq := uniq + 1;
        idx := idx + 1;
      end for;
      simVars := listReverseInPlace(simVars);
      indices.uniqueIndex := uniq;
      indices := setTypeIndex(indices, varType, idx);
    end createList;

    function createListsByType
      "One SimVar list per basic type (real, integer, boolean, string, enumeration),
      each with its own running index."
      input list<Pointer<Variable>> vars;
      input VarType varType;
      output list<list<SimVar>> simVars;
      input output SimCode.SimCodeIndices indices;
    protected
      Integer uniq = indices.uniqueIndex;
      Integer real_idx, int_idx, bool_idx, string_idx, enum_idx;
      list<SimVar> real_lst = {}, int_lst = {}, bool_lst = {}, string_lst = {}, enum_lst = {};
      Variable var;
      Alias alias;
    algorithm
      (real_idx, int_idx, bool_idx, string_idx, enum_idx) := getTypeIndices(indices, varType);
      for var_ptr in vars loop
        var := Pointer.access(var_ptr);
        alias := if varType == VarType.ALIAS then Alias.fromBinding(var.binding) else Alias.NO_ALIAS();
        () := match Type.arrayElementType(var.ty)
          case Type.REAL() algorithm
            real_lst := create(var, uniq, real_idx, alias) :: real_lst;
            real_idx := real_idx + 1;
            uniq := uniq + 1;
          then ();

          case Type.INTEGER() algorithm
            int_lst := create(var, uniq, int_idx, alias) :: int_lst;
            int_idx := int_idx + 1;
            uniq := uniq + 1;
          then ();

          case Type.BOOLEAN() algorithm
            bool_lst := create(var, uniq, bool_idx, alias) :: bool_lst;
            bool_idx := bool_idx + 1;
            uniq := uniq + 1;
          then ();

          case Type.STRING() algorithm
            string_lst := create(var, uniq, string_idx, alias) :: string_lst;
            string_idx := string_idx + 1;
            uniq := uniq + 1;
          then ();

          case Type.ENUMERATION() algorithm
            enum_lst := create(var, uniq, enum_idx, alias) :: enum_lst;
            enum_idx := enum_idx + 1;
            uniq := uniq + 1;
          then ();

          // clock variables do not exist anymore
          case Type.CLOCK() then ();

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unhandled Variable " + ComponentRef.toString(var.name) + "."});
          then fail();
        end match;
      end for;
      simVars := {listReverseInPlace(real_lst), listReverseInPlace(int_lst), listReverseInPlace(bool_lst),
                  listReverseInPlace(string_lst), listReverseInPlace(enum_lst)};
      indices.uniqueIndex := uniq;
      indices := setTypeIndices(indices, varType, real_idx, int_idx, bool_idx, string_idx, enum_idx);
    end createListsByType;

    function getTypeIndex
      input SimCode.SimCodeIndices indices;
      input VarType varType;
      output Integer idx;
    algorithm
      idx := match varType
        case VarType.SIMULATION       then indices.realVarIndex;
        case VarType.PARAMETER        then indices.realParamIndex;
        case VarType.ALIAS            then indices.realAliasIndex;
        case VarType.RESIDUAL         then indices.residualIndex;
        case VarType.EXTERNAL_OBJECT  then indices.extObjIndex;
      end match;
    end getTypeIndex;

    function setTypeIndex
      input output SimCode.SimCodeIndices indices;
      input VarType varType;
      input Integer idx;
    algorithm
      () := match varType
        case VarType.SIMULATION       algorithm indices.realVarIndex := idx;   then ();
        case VarType.PARAMETER        algorithm indices.realParamIndex := idx; then ();
        case VarType.ALIAS            algorithm indices.realAliasIndex := idx; then ();
        case VarType.RESIDUAL         algorithm indices.residualIndex := idx;  then ();
        case VarType.EXTERNAL_OBJECT  algorithm indices.extObjIndex := idx;    then ();
      end match;
    end setTypeIndex;

    function getTypeIndices
      input SimCode.SimCodeIndices indices;
      input VarType varType;
      output Integer real_idx;
      output Integer int_idx;
      output Integer bool_idx;
      output Integer string_idx;
      output Integer enum_idx;
    algorithm
      (real_idx, int_idx, bool_idx, string_idx, enum_idx) := match varType
        case VarType.SIMULATION then (indices.realVarIndex, indices.integerVarIndex, indices.booleanVarIndex, indices.stringVarIndex, indices.enumerationVarIndex);
        case VarType.PARAMETER  then (indices.realParamIndex, indices.integerParamIndex, indices.booleanParamIndex, indices.stringParamIndex, indices.enumerationParamIndex);
        case VarType.ALIAS      then (indices.realAliasIndex, indices.integerAliasIndex, indices.booleanAliasIndex, indices.stringAliasIndex, indices.enumerationAliasIndex);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unhandled VarType."});
        then fail();
      end match;
    end getTypeIndices;

    function setTypeIndices
      input output SimCode.SimCodeIndices indices;
      input VarType varType;
      input Integer real_idx;
      input Integer int_idx;
      input Integer bool_idx;
      input Integer string_idx;
      input Integer enum_idx;
    algorithm
      () := match varType
        case VarType.SIMULATION algorithm
          indices.realVarIndex := real_idx;
          indices.integerVarIndex := int_idx;
          indices.booleanVarIndex := bool_idx;
          indices.stringVarIndex := string_idx;
          indices.enumerationVarIndex := enum_idx;
        then ();
        case VarType.PARAMETER algorithm
          indices.realParamIndex := real_idx;
          indices.integerParamIndex := int_idx;
          indices.booleanParamIndex := bool_idx;
          indices.stringParamIndex := string_idx;
          indices.enumerationParamIndex := enum_idx;
        then ();
        case VarType.ALIAS algorithm
          indices.realAliasIndex := real_idx;
          indices.integerAliasIndex := int_idx;
          indices.booleanAliasIndex := bool_idx;
          indices.stringAliasIndex := string_idx;
          indices.enumerationAliasIndex := enum_idx;
        then ();
      end match;
    end setTypeIndices;

    function createFromResidualComponent
      input output StrongComponent comp;
      input Pointer<list<SimVar>> acc;
      input Pointer<SimCode.SimCodeIndices> indices_ptr;
      input VarType varType = VarType.SIMULATION;
    algorithm
      () := match comp
        case StrongComponent.SINGLE_COMPONENT() guard(Equation.isResidual(comp.eqn)) algorithm
          traverseCreate(Pointer.access(Equation.getResidualVar(comp.eqn)), acc, indices_ptr, varType);
        then ();
        else ();
      end match;
    end createFromResidualComponent;

    function size
      input SimVar var;
      output Integer s = Type.sizeOf(var.type_);
    end size;

    function getName
      input SimVar var;
      output ComponentRef name = var.name;
    end getName;

    function getIndex
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, SimVar> sim_map;
      output Integer index;
    protected
      SimVar var;
    algorithm
      try
        var := UnorderedMap.getSafe(cref, sim_map, sourceInfo());
        index := var.index;
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get index for cref: " + ComponentRef.toString(cref)});
        fail();
      end try;
    end getIndex;

    function shiftIndex
      "Shift index by some value. Used to append `enumVars` onto `intVars`."
      input output SimVar var;
      input Integer shift;
    algorithm
      var.index := var.index + shift;
      if isSome(var.fmi_index) then
        var.fmi_index := SOME(Util.getOption(var.fmi_index) + shift);
      end if;
    end shiftIndex;

    function convert
      input SimVar simVar;
      output OldSimCodeVar.SimVar oldSimVar;
    protected
      DAE.ComponentRef name = ComponentRef.toDAE(simVar.name);
    algorithm
      oldSimVar := OldSimCodeVar.SIMVAR(
        name                = name,
        varKind             = convertVarKind(simVar.varKind),
        comment             = simVar.comment,
        unit                = simVar.unit,
        displayUnit         = simVar.displayUnit,
        index               = simVar.index,
        minValue            = convertAttribute(simVar.min),
        maxValue            = convertAttribute(simVar.max),
        initialValue        = convertAttribute(simVar.start),
        nominalValue        = convertAttribute(simVar.nominal),
        isFixed             = simVar.isFixed,
        type_               = Type.toDAE(simVar.type_),
        isDiscrete          = simVar.isDiscrete,
        arrayCref           = Util.applyOption(simVar.arrayCref, ComponentRef.toDAE),
        aliasvar            = Alias.convert(simVar.aliasvar),
        source              = DAE.emptyElementSource, //ToDo update this!
        causality           = Util.applyOption(simVar.causality, convertCausality),
        variable_index      = simVar.variable_index,
        fmi_index           = simVar.fmi_index,
        numArrayElement     = list(Expression.toString(e) for e in simVar.numArrayElement),
        isValueChangeable   = simVar.isValueChangeable,
        isProtected         = simVar.isProtected,
        hideResult          = SOME(simVar.hideResult),
        isEncrypted         = simVar.isEncrypted,
        inputIndex          = simVar.inputIndex,
        initNonlinear       = false,  // TODO: Check what to add here!
        matrixName          = simVar.matrixName,
        variability         = SOME(convertVariability(simVar.varKind)),
        initial_            = convertInitial(convertVariability(simVar.varKind), Util.applyOption(simVar.causality, convertCausality)),
        exportVar           = convertExportVar(simVar.exportVar, simVar.name, name),
        relativeQuantity    = false,
        isConnectorFlow     = simVar.isConnectorFlow);
    end convert;

    function convertExportVar
      "the export variable is the variable itself unless something replaced it,
      so the converted name is usually the same cref again"
      input Option<ComponentRef> exportVar;
      input ComponentRef varName;
      input DAE.ComponentRef converted "varName converted";
      output Option<DAE.ComponentRef> dcref;
    algorithm
      dcref := match exportVar
        local ComponentRef cref;
        case SOME(cref) then SOME(if referenceEq(cref, varName) then converted else ComponentRef.toDAE(cref));
        else NONE();
      end match;
    end convertExportVar;

    function convertAttribute
      "Util.applyOption would build the partial application once per attribute
      and variable, which is millions of closures on a scalarized model."
      input Option<Expression> exp;
      output Option<DAE.Exp> dexp;
    algorithm
      dexp := match exp
        local Expression e;
        case SOME(e) then SOME(Expression.toDAE(e, allowEmpty = false));
        else NONE();
      end match;
    end convertAttribute;

    function convertCausality
      "Convert the new-backend Causality enum to the old SimCodeVar.Causality used
       by the FMI model-description templates."
      input Causality c;
      output OldSimCodeVar.Causality oc;
    algorithm
      oc := match c
        case Causality.NONE                 then OldSimCodeVar.NONECAUS();
        case Causality.OUTPUT               then OldSimCodeVar.OUTPUT();
        case Causality.INPUT                then OldSimCodeVar.INPUT();
        case Causality.LOCAL                then OldSimCodeVar.LOCAL();
        case Causality.PARAMETER            then OldSimCodeVar.PARAMETER();
        case Causality.CALCULATED_PARAMETER then OldSimCodeVar.CALCULATED_PARAMETER();
      end match;
    end convertCausality;

    function convertVariability
      "Derive the FMI variability attribute from the variable kind."
      input VariableKind vk;
      output OldSimCodeVar.Variability v;
    algorithm
      v := match vk
        case VariableKind.CONSTANT()       then OldSimCodeVar.CONSTANT();
        case VariableKind.PARAMETER()      then OldSimCodeVar.FIXED();
        case VariableKind.DISCRETE()       then OldSimCodeVar.DISCRETE();
        case VariableKind.DISCRETE_STATE() then OldSimCodeVar.DISCRETE();
        case VariableKind.CLOCKED()        then OldSimCodeVar.DISCRETE();
        case VariableKind.PREVIOUS()       then OldSimCodeVar.DISCRETE();
        else OldSimCodeVar.CONTINUOUS();
      end match;
    end convertVariability;

    function convertInitial
      "Default FMI initial attribute from variability + causality (mirrors
       SimCodeUtil.getDefaultFmiInitialAttribute). Only the EXACT cases matter
       for now: they make the start value be emitted to modelDescription.xml."
      input OldSimCodeVar.Variability v;
      input Option<OldSimCodeVar.Causality> c;
      output Option<OldSimCodeVar.Initial> initial_;
    algorithm
      initial_ := match (v, c)
        case (OldSimCodeVar.CONSTANT(), _)                                  then SOME(OldSimCodeVar.EXACT());
        case (OldSimCodeVar.FIXED(),   SOME(OldSimCodeVar.PARAMETER()))     then SOME(OldSimCodeVar.EXACT());
        case (OldSimCodeVar.TUNABLE(), SOME(OldSimCodeVar.PARAMETER()))     then SOME(OldSimCodeVar.EXACT());
        else NONE();
      end match;
    end convertInitial;

    function convertList
      input list<SimVar> simVar_lst;
      output list<OldSimCodeVar.SimVar> oldSimVar_lst = list(convert(simVar) for simVar in simVar_lst);
    end convertList;

    function newConvertMemo
      input Integer size;
      output ConvertMemo memo = UnorderedMap.new<ConvertEntry>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(size));
    end newConvertMemo;

    function convertMemo
      input SimVar simVar;
      input ConvertMemo memo;
      output OldSimCodeVar.SimVar oldSimVar = convert(simVar);
    algorithm
      UnorderedMap.add(simVar.name, (simVar, oldSimVar), memo);
    end convertMemo;

    function convertListMemo
      input list<SimVar> simVar_lst;
      input ConvertMemo memo;
      output list<OldSimCodeVar.SimVar> oldSimVar_lst = list(convertMemo(simVar, memo) for simVar in simVar_lst);
    end convertListMemo;

    function convertMemoized
      "the remembered conversion of exactly this record, or a fresh one"
      input SimVar simVar;
      input ConvertMemo memo;
      output OldSimCodeVar.SimVar oldSimVar;
    protected
      SimVar orig;
    algorithm
      oldSimVar := match UnorderedMap.get(simVar.name, memo)
        case SOME((orig, oldSimVar)) guard referenceEq(orig, simVar) then oldSimVar;
        else convert(simVar);
      end match;
    end convertMemoized;

    function convertTpl
      input tuple<SimVar, Boolean> tpl;
      output tuple<OldSimCodeVar.SimVar, Boolean> oldTpl;
    protected
      SimVar var;
      Boolean b;
    algorithm
      (var, b) := tpl;
      oldTpl := (convert(var), b);
    end convertTpl;

    function isOutputSimVar
      "True if the SimVar is an FMI output (causality OUTPUT), used to collect the
       output interface variables (the new backend has no top-level-output list)."
      input SimVar v;
      output Boolean b;
    algorithm
      b := match v.causality
        case SOME(Causality.OUTPUT) then true;
        else false;
      end match;
    end isOutputSimVar;

  protected
    function parseAttributes
      input BackendInfo backendInfo;
      output VariableKind varKind;
      output String unit = "";
      output String displayUnit = "";
      output Option<Expression> min = NONE();
      output Option<Expression> max = NONE();
      output Option<Expression> start = NONE();
      output Option<Expression> nominal = NONE();
      output Boolean isFixed = false;
      output Boolean isDiscrete;
      output Boolean isProtected;
    algorithm
      () := match backendInfo
        local
          VariableAttributes varAttr;

        case BackendInfo.BACKEND_INFO(varKind = varKind, attributes = varAttr as VariableAttributes.VAR_ATTR_REAL())
          algorithm
            unit        := Util.applyOptionOrDefault(Util.applyOption(varAttr.unit,        Binding.getTypedExp), Expression.stringValue, "");
            displayUnit := Util.applyOptionOrDefault(Util.applyOption(varAttr.displayUnit, Binding.getTypedExp), Expression.stringValue, "");
            min         := Util.applyOption(varAttr.min,     Binding.getTypedExp);
            max         := Util.applyOption(varAttr.max,     Binding.getTypedExp);
            start       := Util.applyOption(varAttr.start,   Binding.getTypedExp);
            nominal     := Util.applyOption(varAttr.nominal, Binding.getTypedExp);
            // FIXME parameters have default fixed = true
            isFixed     := Util.applyOptionOrDefault(Util.applyOption(varAttr.fixed, Binding.getTypedExp), Expression.isAllTrue, false);
            isDiscrete := match varKind
              case VariableKind.DISCRETE()        then true;
              case VariableKind.DISCRETE_STATE()  then true;
              case VariableKind.PREVIOUS()        then true;
              case VariableKind.PARAMETER()       then true;
              case VariableKind.CONSTANT()        then true;
              case VariableKind.START()           then true;
                                                  else false;
            end match;
            isProtected := Util.getOptionOrDefault(varAttr.isProtected, false);
        then ();

        case BackendInfo.BACKEND_INFO(varKind = varKind, attributes = varAttr as VariableAttributes.VAR_ATTR_INT())
          algorithm
            min     := Util.applyOption(varAttr.min,   Binding.getTypedExp);
            max     := Util.applyOption(varAttr.max,   Binding.getTypedExp);
            start   := Util.applyOption(varAttr.start, Binding.getTypedExp);
            isFixed := Util.applyOptionOrDefault(Util.applyOption(varAttr.fixed, Binding.getTypedExp), Expression.isAllTrue, false);
            isDiscrete := true;
            isProtected := Util.getOptionOrDefault(varAttr.isProtected, false);
        then ();

        case BackendInfo.BACKEND_INFO(varKind = varKind, attributes = varAttr as VariableAttributes.VAR_ATTR_BOOL())
          algorithm
            start   := Util.applyOption(varAttr.start, Binding.getTypedExp);
            isFixed := Util.applyOptionOrDefault(Util.applyOption(varAttr.fixed, Binding.getTypedExp), Expression.isAllTrue, false);
            isDiscrete := true;
            isProtected := Util.getOptionOrDefault(varAttr.isProtected, false);
        then ();

        case BackendInfo.BACKEND_INFO(varKind = varKind, attributes = varAttr as VariableAttributes.VAR_ATTR_CLOCK())
          algorithm
            isDiscrete := true;
            isProtected := Util.getOptionOrDefault(varAttr.isProtected, false);
        then ();

        case BackendInfo.BACKEND_INFO(varKind = varKind, attributes = varAttr as VariableAttributes.VAR_ATTR_STRING())
          algorithm
            start   := Util.applyOption(varAttr.start, Binding.getTypedExp);
            isFixed := Util.applyOptionOrDefault(Util.applyOption(varAttr.fixed, Binding.getTypedExp), Expression.isAllTrue, false);
            isDiscrete := true;
            isProtected := Util.getOptionOrDefault(varAttr.isProtected, false);
        then ();

        case BackendInfo.BACKEND_INFO(varKind = varKind, attributes = varAttr as VariableAttributes.VAR_ATTR_ENUMERATION())
          algorithm
            min     := Util.applyOption(varAttr.min,   Binding.getTypedExp);
            max     := Util.applyOption(varAttr.max,   Binding.getTypedExp);
            start   := Util.applyOption(varAttr.start, Binding.getTypedExp);
            isFixed := Util.applyOptionOrDefault(Util.applyOption(varAttr.fixed, Binding.getTypedExp), Expression.isAllTrue, false);
            isDiscrete := true;
            isProtected := Util.getOptionOrDefault(varAttr.isProtected, false);
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the BackendInfo could not be parsed:\n"
            + BackendInfo.toString(backendInfo)});
        then fail();
      end match;
    end parseAttributes;

    function parseComment
      input SCode.Comment absynComment;
      output String commentStr;
    algorithm
      commentStr := match absynComment
        case SCode.COMMENT(comment = SOME(commentStr)) then commentStr;
        else "";
      end match;
    end parseComment;

    function parseBinding
      "returns the binding expression if the variable is a parameter and the binding is constant
       returns the original start expression otherwise. Only if the binding is constant and used
       as initial"
      input output Option<Expression> start;
      output Boolean isValueChangeable;
      output Causality causality;
      input Variable var;
    algorithm
      (start, isValueChangeable, causality) := match var
        local
          Expression bindingExp;

        // 1. parameter with constant binding -> start value is updated to the binding value. Value can be changed after sim
        case Variable.VARIABLE(binding = Binding.TYPED_BINDING(variability = NFPrefixes.Variability.CONSTANT, bindingExp = bindingExp),
          backendinfo = BackendInfo.BACKEND_INFO(varKind = VariableKind.PARAMETER()))
        then (SOME(bindingExp), true, Causality.PARAMETER);

        // 2. just like 1. - FLAT_BINDING gets introduced by expanding/scalarizing
        case Variable.VARIABLE(binding = Binding.FLAT_BINDING(variability = NFPrefixes.Variability.CONSTANT, bindingExp = bindingExp),
          backendinfo = BackendInfo.BACKEND_INFO(varKind = VariableKind.PARAMETER()))
        then (SOME(bindingExp), true, Causality.PARAMETER);

        // 3. parameter with non constant binding -> normal start value. Value cannot be changed after simulation
        case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(varKind = VariableKind.PARAMETER()))
        then (start, false, Causality.CALCULATED_PARAMETER);

        // 4. top level input / output variables -> FMI input/output causality (the
        //    flat-model direction; mirrors the old backend so modelDescription.xml
        //    gets causality="input"/"output" and FMI 3.0 terminals get a direction)
        case _ guard Variable.isInput(var)  then (start, true,  Causality.INPUT);
        case _ guard Variable.isOutput(var) then (start, false, Causality.OUTPUT);

        // 0. other variables -> regular start value and it can be changed after simulation
        else (start, false, Causality.LOCAL);

        // ToDo: more cases!

        // FIXME: variables that are fixed and are not CALCULATED should have isValueChangeable=true
      end match;
    end parseBinding;

    function convertVarKind
      "Usually this function would belong to NFBackendExtension, but we want to
      avoid Frontend -> Backend dependency."
      input VariableKind varKind;
      output OldBackendDAE.VarKind oldVarKind;
    algorithm
      oldVarKind := match varKind
        local
          Variable var;
          Option<DAE.ComponentRef> oldCrefOpt;

        case VariableKind.ALGEBRAIC()               then OldBackendDAE.VARIABLE();
        case VariableKind.STATE()
          algorithm
            if isSome(varKind.derivative) then
              var := Pointer.access(Util.getOption(varKind.derivative));
              oldCrefOpt := SOME(ComponentRef.toDAE(var.name));
            else
              oldCrefOpt := NONE();
            end if;
        then OldBackendDAE.STATE(varKind.index, oldCrefOpt, varKind.natural);
        case VariableKind.STATE_DER()               then OldBackendDAE.STATE_DER();
        case VariableKind.DUMMY_DER()               then OldBackendDAE.DUMMY_DER();
        case VariableKind.DUMMY_STATE()             then OldBackendDAE.DUMMY_STATE();
        case VariableKind.DISCRETE()                then OldBackendDAE.DISCRETE();
        case VariableKind.DISCRETE_STATE()          then OldBackendDAE.DISCRETE(); // we don't distinguish between clocked, discrete states and discretes in the old backend. is this correct?
        case VariableKind.CLOCKED()                 then OldBackendDAE.DISCRETE(); // we don't distinguish between clocked, discrete states and discretes in the old backend. is this correct?
        case VariableKind.PREVIOUS()                then OldBackendDAE.DISCRETE();
        case VariableKind.PARAMETER()               then OldBackendDAE.PARAM();
        case VariableKind.CONSTANT()                then OldBackendDAE.CONST();
        //ToDo: check this! is this correct? need typechecking?
        case VariableKind.START()                   then OldBackendDAE.VARIABLE();
        case VariableKind.EXTOBJ()                  then OldBackendDAE.EXTOBJ(varKind.fullClassName);
        case VariableKind.JAC_VAR()                 then OldBackendDAE.JAC_VAR();
        case VariableKind.JAC_TMP_VAR()             then OldBackendDAE.JAC_TMP_VAR();
        case VariableKind.SEED_VAR()                then OldBackendDAE.SEED_VAR();
        case VariableKind.OPT_CONSTR()              then OldBackendDAE.OPT_CONSTR();
        case VariableKind.OPT_FCONSTR()             then OldBackendDAE.OPT_FCONSTR();
        case VariableKind.OPT_INPUT_WITH_DER()      then OldBackendDAE.OPT_INPUT_WITH_DER();
        case VariableKind.OPT_INPUT_DER()           then OldBackendDAE.OPT_INPUT_DER();
        case VariableKind.OPT_TGRID()               then OldBackendDAE.OPT_TGRID();
        case VariableKind.OPT_LOOP_INPUT()          then OldBackendDAE.OPT_LOOP_INPUT(ComponentRef.toDAE(varKind.replaceCref));
        // ToDo maybe deprecated:
        case VariableKind.ALG_STATE()               then OldBackendDAE.ALG_STATE();
        case VariableKind.ALG_STATE_OLD()           then OldBackendDAE.ALG_STATE_OLD();
        case VariableKind.RESIDUAL_VAR()            then OldBackendDAE.DAE_RESIDUAL_VAR();
        case VariableKind.DAE_AUX_VAR()             then OldBackendDAE.DAE_AUX_VAR();
        case VariableKind.LOOP_ITERATION()          then OldBackendDAE.LOOP_ITERATION();
        case VariableKind.LOOP_SOLVED()             then OldBackendDAE.LOOP_SOLVED();
        case VariableKind.FRONTEND_DUMMY()
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong VariableKind FRONTEND_DUMMY(). This should not exist after frontend."});
        then fail();
        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unhandled VariableKind " + VariableKind.toString(varKind) + "."});
        then fail();
      end match;
    end convertVarKind;
  end SimVar;

  uniontype Alias
    record NO_ALIAS end NO_ALIAS;

    record ALIAS
      "General alias expression with a coefficent.
      var := gain * alias + offset"
      ComponentRef alias    "The name of the alias variable.";
      Real gain             " = 1 for regular alias.";
      Real offset           " = 0 for regular alias.";
    end ALIAS;

    function fromBinding
      input Binding binding;
      output Alias alias;
    algorithm
      alias := match binding
        case Binding.TYPED_BINDING()  then getAlias(binding.bindingExp);
        case Binding.FLAT_BINDING()   then getAlias(binding.bindingExp);
        else NO_ALIAS();
      end match;
    end fromBinding;

    function toString
      input Alias alias;
      output String str;
    algorithm
      str := match alias
        local
          String gainStr, offsetStr;
        case NO_ALIAS() then "(no alias)";
        case ALIAS() algorithm
          gainStr := if alias.gain == 1.0 then "" else realString(alias.gain) + "*";
          offsetStr := if alias.offset == 0.0 then "" else "+" + realString(alias.offset);
        then "(bound alias: " + gainStr + ComponentRef.toString(alias.alias) + offsetStr + ")";
      end match;
    end toString;

    function convert
      input Alias alias;
      output OldSimCodeVar.AliasVariable oldAlias;
    algorithm
      oldAlias := match alias
        case NO_ALIAS() then OldSimCodeVar.NOALIAS();

        case ALIAS() guard(realEq(alias.gain, 1.0) and realEq(alias.offset, 0.0))
        then OldSimCodeVar.ALIAS(ComponentRef.toDAE(alias.alias));

        case ALIAS() guard(realEq(alias.gain, -1.0) and realEq(alias.offset, 0.0))
        then OldSimCodeVar.NEGATEDALIAS(ComponentRef.toDAE(alias.alias));

/* unfortunately not possible in old sim code
        case ALIAS()
        then OldSimCodeVar.ALIAS_FUNC(ComponentRef.toDAE(alias.alias), alias.gain, alias.offset);
*/
        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown Alias type."});
        then fail();
      end match;
    end convert;

  protected
    function getAlias
      input Expression exp;
      output Alias alias;
    algorithm

      alias := match SimplifyExp.simplify(exp)
        local
          Expression e;
          ComponentRef cref;

        // equality alias
        case e as Expression.CREF()                         then ALIAS(e.cref, 1.0, 0.0);

        // negated alias
        case Expression.UNARY(exp = e as Expression.CREF()) then ALIAS(e.cref, -1.0, 0.0);

        // negated logical alias
        case Expression.LUNARY(exp = e as Expression.CREF()) then ALIAS(e.cref, -1.0, 0.0);
/*
        // gain alias
        case e as Expression.MULTARY(arguments = {e1, e2}, inv_arguments = {})
          guard(Operator.getMathClassification(e.operator) == NFOperator.MathClassification.MULTIPLICATION)
          algorithm
            (cref, gain) := getGainAlias(e1, e2);
        then ALIAS(cref, gain, 0.0);

        // offset alias (possibly also gain alias)
        // constant should always be simplified to the arguments list even if it is negative
        case e as Expression.MULTARY(arguments = {e1, e2}, inv_arguments = {})
          guard(Operator.getMathClassification(e.operator) == NFOperator.MathClassification.ADDITION)
          algorithm
            (cref, gain, offset) := getOffsetAlias(e1, e2);
        then ALIAS(cref, gain, offset);
*/
        else NO_ALIAS();
      end match;
    end getAlias;

    function getGainAlias
      input Expression e1;
      input Expression e2;
      output ComponentRef cref;
      output Real gain;
    algorithm
      (cref, gain) := match(e1, e2)
        // first argument is the cref and second is const
        case (Expression.CREF(), _) guard(Expression.isConstNumber(e2)) then (e1.cref, Expression.realValue(e2));
        // secoond argument is the cref and first is const
        case (_, Expression.CREF()) guard(Expression.isConstNumber(e1)) then (e2.cref, Expression.realValue(e1));
        else algorithm
          Error.addInternalError(getInstanceName() + " cannot generate gain alias from Expressions: {"
            + Expression.toString(e1) + ", " + Expression.toString(e2) + "}", sourceInfo());
        then fail();
      end match;
    end getGainAlias;

    function getOffsetAlias
      input Expression e1;
      input Expression e2;
      output ComponentRef cref;
      output Real gain;
      output Real offset;
    algorithm
      (cref, gain, offset) := match (e1, e2)
        local
          Expression arg1, arg2;

        // first argument is the cref and second is const
        case (Expression.CREF(), _) guard(Expression.isConstNumber(e2)) then (e1.cref, 0.0, Expression.realValue(e2));

        // second is the cref and first is const
        case (_, Expression.CREF()) guard(Expression.isConstNumber(e1)) then (e2.cref, 0.0, Expression.realValue(e1));

        // first argument is a multiplication with two arguments, second is constant
        // check if multiplication represents simple gain
        case (Expression.MULTARY(arguments = {arg1, arg2}, inv_arguments = {}), _)
          guard((Operator.getMathClassification(e1.operator) == NFOperator.MathClassification.MULTIPLICATION)
                and Expression.isConstNumber(e2))
          algorithm
            (cref, gain) := getGainAlias(arg1, arg2);
          then (cref, gain, Expression.realValue(e2));

        // second argument is a multiplication with two arguments, first is constant
        // check if multiplication represents simple gain
        case (_, Expression.MULTARY(arguments = {arg1, arg2}, inv_arguments = {}))
          guard((Operator.getMathClassification(e2.operator) == NFOperator.MathClassification.MULTIPLICATION)
                and Expression.isConstNumber(e1))
          algorithm
            (cref, gain) := getGainAlias(arg1, arg2);
          then (cref, gain, Expression.realValue(e1));

        else algorithm
          Error.addInternalError(getInstanceName() + " cannot generate offset alias from Expressions: {"
            + Expression.toString(e1) + ", " + Expression.toString(e2) + "}", sourceInfo());
        then fail();
      end match;
    end getOffsetAlias;
  end Alias;

  // kabdelhak: i don't like "CALCULATED_PARAMETER", is there a better way to describe it?
  type Causality = enumeration(NONE, OUTPUT, INPUT, LOCAL, PARAMETER, CALCULATED_PARAMETER);
  // kabdelhak: where is the difference between approx and calculated?
  type Initial = enumeration(NONE, EXACT, APPROX, CALCULATED);
  // kabdelhak: i don't like "TUNABLE" -> just "VARIABLE"?
  type Variability = enumeration(CONSTANT, FIXED, TUNABLE, DISCRETE, CONTINUOUS);

  uniontype SimVars "Container for metadata about variables in a Modelica model."
    record SIMVARS
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> discreteAlgVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> stringAlgVars;
      list<SimVar> enumAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> stringAliasVars;
      list<SimVar> enumAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringParamVars;
      list<SimVar> enumParamVars;
      list<SimVar> extObjVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
      list<SimVar> enumConstVars;
      list<SimVar> residualVars;
      list<SimVar> jacobianVars;
      list<SimVar> seedVars;
      list<SimVar> realOptimizeConstraintsVars;
      list<SimVar> realOptimizeFinalConstraintsVars;
      list<SimVar> sensitivityVars "variable used to calculate sensitivities for parameters nSensitivitityParameters + nRealParam*nStates";
      list<SimVar> dataReconSetcVars;
      list<SimVar> dataReconinputVars;
      list<SimVar> dataReconSetBVars;
    end SIMVARS;

    function toString
      input SimVars vars;
      input output String str = "";
    algorithm
      str := StringUtil.headline_2("SimVars " + str);
      str := str + SimVar.listToString(vars.stateVars, "States");
      str := str + SimVar.listToString(vars.derivativeVars, "Derivatives");
      str := str + SimVar.listToString(vars.algVars, "Algebraic Variables");
      str := str + SimVar.listToString(vars.discreteAlgVars, "Discrete Algebraic Variables");
      str := str + SimVar.listToString(vars.intAlgVars, "Integer Algebraic Variables");
      str := str + SimVar.listToString(vars.boolAlgVars, "Boolean Algebraic Variables");
      str := str + SimVar.listToString(vars.paramVars, "Real Parameters");
      str := str + SimVar.listToString(vars.intParamVars, "Integer Parameters");
      str := str + SimVar.listToString(vars.boolParamVars, "Boolean Parameters");
      str := str + SimVar.listToString(vars.residualVars, "Residual Variables");
      str := str + SimVar.listToString(vars.aliasVars, "Real Alias", true);
      // ToDo: all the other stuff
    end toString;

    function create
      input BVariable.VarData varData;
      input VariablePointers residual_vars;
      output SimVars simVars;
      input output SimCode.SimCodeIndices simCodeIndices;
    protected
      list<SimVar> stateVars = {}, derivativeVars = {}, algVars = {}, nonTrivialAlias = {};
      list<SimVar> discreteAlgVars = {}, intAlgVars = {}, boolAlgVars = {}, stringAlgVars = {}, enumAlgVars = {};
      list<SimVar> discreteAlgVars2 = {}, intAlgVars2 = {}, boolAlgVars2 = {}, stringAlgVars2 = {}, enumAlgVars2 = {};
      list<SimVar> discreteAlgVars3 = {}, intAlgVars3 = {}, boolAlgVars3 = {}, stringAlgVars3 = {}, enumAlgVars3 = {};
      list<SimVar> inputVars = {};
      list<SimVar> outputVars = {};
      list<SimVar> aliasVars = {}, intAliasVars = {}, boolAliasVars = {}, stringAliasVars = {}, enumAliasVars = {};
      list<SimVar> paramVars = {}, intParamVars = {}, boolParamVars = {}, stringParamVars = {}, enumParamVars = {};
      list<SimVar> paramVarsR = {}, intParamVarsR = {}, boolParamVarsR = {}, stringParamVarsR = {}, enumParamVarsR = {};
      list<SimVar> constVars = {}, intConstVars = {}, boolConstVars = {}, stringConstVars = {}, enumConstVars = {};
      list<SimVar> extObjVars = {};
      list<SimVar> residualVars = {};
      list<SimVar> jacobianVars = {};
      list<SimVar> seedVars = {};
      list<SimVar> realOptimizeConstraintsVars = {};
      list<SimVar> realOptimizeFinalConstraintsVars = {};
      list<SimVar> sensitivityVars = {};
      list<SimVar> dataReconSetcVars = {};
      list<SimVar> dataReconinputVars = {};
      list<SimVar> dataReconSetBVars = {};
    algorithm
      () := match varData
        case BVariable.VAR_DATA_SIM() algorithm
          ({stateVars}, simCodeIndices)                                                                   := createSimVarLists(varData.states, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
          ({derivativeVars}, simCodeIndices)                                                              := createSimVarLists(varData.derivatives, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
          ({algVars}, simCodeIndices)                                                                     := createSimVarLists(varData.algebraics, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
          ({inputVars}, simCodeIndices)                                                                   := createSimVarLists(varData.top_level_inputs, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
          ({nonTrivialAlias}, simCodeIndices)                                                             := createSimVarLists(varData.nonTrivialAlias, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
          ({discreteAlgVars, intAlgVars, boolAlgVars, stringAlgVars, enumAlgVars}, simCodeIndices)        := createSimVarLists(varData.discretes, simCodeIndices, SplitType.TYPE, VarType.SIMULATION);
          ({discreteAlgVars2, intAlgVars2, boolAlgVars2, stringAlgVars2, enumAlgVars2}, simCodeIndices)   := createSimVarLists(varData.discrete_states, simCodeIndices, SplitType.TYPE, VarType.SIMULATION);
          ({discreteAlgVars3, intAlgVars3, boolAlgVars3, stringAlgVars3, enumAlgVars3}, simCodeIndices)   := createSimVarLists(varData.clocked_states, simCodeIndices, SplitType.TYPE, VarType.SIMULATION);
          ({aliasVars, intAliasVars, boolAliasVars, stringAliasVars, enumAliasVars}, simCodeIndices)      := createSimVarLists(varData.aliasVars, simCodeIndices, SplitType.TYPE, VarType.ALIAS);
          ({paramVars, intParamVars, boolParamVars, stringParamVars, enumParamVars}, simCodeIndices)      := createSimVarLists(varData.parameters, simCodeIndices, SplitType.TYPE, VarType.PARAMETER);
          ({paramVarsR, intParamVarsR, boolParamVarsR, stringParamVarsR, enumParamVarsR}, simCodeIndices) := createSimVarLists(varData.resizables, simCodeIndices, SplitType.TYPE, VarType.PARAMETER);
          ({constVars, intConstVars, boolConstVars, stringConstVars, enumConstVars}, simCodeIndices)      := createSimVarLists(varData.constants, simCodeIndices, SplitType.TYPE, VarType.SIMULATION);
          ({residualVars}, simCodeIndices)                                                                := createSimVarLists(residual_vars, simCodeIndices, SplitType.NONE, VarType.RESIDUAL);
          // The new backend has no separate top-level-output partition; outputs are
          // algebraic/state/discrete variables flagged OUTPUT by parseBinding. Collect
          // them across ALL base types (real, integer, boolean, string, enum) for the
          // FMI inputVars/outputVars interface (used e.g. by the FMI 3.0 terminal
          // export and ModelStructure). The variables stay in their original lists too.
          outputVars := List.filterOnTrue(
            List.flatten({stateVars, algVars,
                          discreteAlgVars, discreteAlgVars2, discreteAlgVars3,
                          intAlgVars, intAlgVars2, intAlgVars3,
                          boolAlgVars, boolAlgVars2, boolAlgVars3,
                          stringAlgVars, stringAlgVars2, stringAlgVars3,
                          enumAlgVars, enumAlgVars2, enumAlgVars3}),
            SimVar.isOutputSimVar);
        then ();
        case BVariable.VAR_DATA_JAC() then ();
        case BVariable.VAR_DATA_HES() then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;

      simVars := SIMVARS(
        stateVars                         = stateVars,
        derivativeVars                    = derivativeVars,
        algVars                           = List.flatten({algVars, inputVars, nonTrivialAlias}),
        discreteAlgVars                   = List.flatten({discreteAlgVars, discreteAlgVars2, discreteAlgVars3}),
        intAlgVars                        = List.flatten({intAlgVars, intAlgVars2, intAlgVars3}),
        boolAlgVars                       = List.flatten({boolAlgVars, boolAlgVars2, boolAlgVars3}),
        stringAlgVars                     = List.flatten({stringAlgVars, stringAlgVars2, stringAlgVars3}),
        enumAlgVars                       = List.flatten({enumAlgVars, enumAlgVars2, enumAlgVars3}),
        inputVars                         = inputVars,
        outputVars                        = outputVars,
        aliasVars                         = aliasVars,
        intAliasVars                      = intAliasVars,
        boolAliasVars                     = boolAliasVars,
        stringAliasVars                   = stringAliasVars,
        enumAliasVars                     = enumAliasVars,
        paramVars                         = List.flatten({paramVars, paramVarsR}),
        intParamVars                      = List.flatten({intParamVars, intParamVarsR}),
        boolParamVars                     = List.flatten({boolParamVars, boolParamVarsR}),
        stringParamVars                   = List.flatten({stringParamVars, stringParamVarsR}),
        enumParamVars                     = List.flatten({enumParamVars, enumParamVarsR}),
        extObjVars                        = extObjVars,
        constVars                         = constVars,
        intConstVars                      = intConstVars,
        boolConstVars                     = boolConstVars,
        stringConstVars                   = stringConstVars,
        enumConstVars                     = enumConstVars,
        residualVars                      = residualVars,
        jacobianVars                      = jacobianVars,
        seedVars                          = seedVars,
        realOptimizeConstraintsVars       = realOptimizeConstraintsVars,
        realOptimizeFinalConstraintsVars  = realOptimizeFinalConstraintsVars,
        sensitivityVars                   = sensitivityVars,
        dataReconSetcVars                 = dataReconSetcVars,
        dataReconinputVars                = dataReconinputVars,
        dataReconSetBVars                 = dataReconSetBVars
      );

      // FIXME we currently handle enumerations as integers.
      // We append enums to ints so we have to shift the index accordingly.
      simVars.intAlgVars    := listAppend(simVars.intAlgVars, list(SimVar.shiftIndex(v, simCodeIndices.integerVarIndex) for v in simVars.enumAlgVars));
      simVars.intAliasVars  := listAppend(simVars.intAliasVars, list(SimVar.shiftIndex(v, simCodeIndices.integerAliasIndex) for v in simVars.enumAliasVars));
      simVars.intParamVars  := listAppend(simVars.intParamVars, list(SimVar.shiftIndex(v, simCodeIndices.integerParamIndex) for v in simVars.enumParamVars));
      simVars.intConstVars  := listAppend(simVars.intConstVars, list(SimVar.shiftIndex(v, simCodeIndices.integerVarIndex) for v in simVars.enumConstVars));
    end create;

    function addSeedAndJacobianVars
      input output SimVars vars;
      input list<tuple<ComponentRef, SimVar>> hash_tpl;
    protected
      ComponentRef cref;
      SimVar var;
      list<SimVar> seed_vars = {};
      list<SimVar> jacobian_vars = {};
    algorithm
      for tpl in hash_tpl loop
        (cref, var) := tpl;
        if BVariable.checkCref(cref, BVariable.isSeed, sourceInfo()) then
          seed_vars := var :: seed_vars;
        else
          jacobian_vars := var :: jacobian_vars;
        end if;
      end for;
      vars.seedVars := listAppend(seed_vars, vars.seedVars);
      vars.jacobianVars := listAppend(jacobian_vars, vars.jacobianVars);
    end addSeedAndJacobianVars;

    function size
      input SimVars simVars;
      output Integer size = listLength(simVars.stateVars)
                          + listLength(simVars.derivativeVars)
                          + listLength(simVars.algVars)
                          + listLength(simVars.discreteAlgVars)
                          + listLength(simVars.intAlgVars)
                          + listLength(simVars.boolAlgVars)
                          + listLength(simVars.inputVars)
                          + listLength(simVars.outputVars)
                          + listLength(simVars.aliasVars)
                          + listLength(simVars.intAliasVars)
                          + listLength(simVars.boolAliasVars)
                          + listLength(simVars.paramVars)
                          + listLength(simVars.intParamVars)
                          + listLength(simVars.boolParamVars)
                          + listLength(simVars.stringAlgVars)
                          + listLength(simVars.stringParamVars)
                          + listLength(simVars.stringAliasVars)
                          + listLength(simVars.extObjVars)
                          + listLength(simVars.constVars)
                          + listLength(simVars.intConstVars)
                          + listLength(simVars.boolConstVars)
                          + listLength(simVars.stringConstVars)
                          + listLength(simVars.stringAlgVars)
                          + listLength(simVars.jacobianVars)
                          + listLength(simVars.seedVars)
                          + listLength(simVars.realOptimizeConstraintsVars)
                          + listLength(simVars.realOptimizeFinalConstraintsVars)
                          + listLength(simVars.sensitivityVars)
                          + listLength(simVars.dataReconSetcVars)
                          + listLength(simVars.dataReconinputVars)
                          + listLength(simVars.dataReconSetBVars);
    end size;

    function convert
      input SimVars simVars;
      input ConvertMemo memo;
      output OldSimCodeVar.SimVars oldSimVars;
    algorithm
      oldSimVars := OldSimCodeVar.SIMVARS(
        stateVars                         = SimVar.convertListMemo(simVars.stateVars, memo),
        derivativeVars                    = SimVar.convertListMemo(simVars.derivativeVars, memo),
        algVars                           = SimVar.convertListMemo(simVars.algVars, memo),
        discreteAlgVars                   = SimVar.convertListMemo(simVars.discreteAlgVars, memo),
        intAlgVars                        = SimVar.convertListMemo(simVars.intAlgVars, memo),
        boolAlgVars                       = SimVar.convertListMemo(simVars.boolAlgVars, memo),
        inputVars                         = SimVar.convertListMemo(simVars.inputVars, memo),
        outputVars                        = SimVar.convertListMemo(simVars.outputVars, memo),
        aliasVars                         = SimVar.convertListMemo(simVars.aliasVars, memo),
        intAliasVars                      = SimVar.convertListMemo(simVars.intAliasVars, memo),
        boolAliasVars                     = SimVar.convertListMemo(simVars.boolAliasVars, memo),
        paramVars                         = SimVar.convertListMemo(simVars.paramVars, memo),
        intParamVars                      = SimVar.convertListMemo(simVars.intParamVars, memo),
        boolParamVars                     = SimVar.convertListMemo(simVars.boolParamVars, memo),
        stringAlgVars                     = SimVar.convertListMemo(simVars.stringAlgVars, memo),
        stringParamVars                   = SimVar.convertListMemo(simVars.stringParamVars, memo),
        stringAliasVars                   = SimVar.convertListMemo(simVars.stringAliasVars, memo),
        extObjVars                        = SimVar.convertListMemo(simVars.extObjVars, memo),
        constVars                         = SimVar.convertListMemo(simVars.constVars, memo),
        intConstVars                      = SimVar.convertListMemo(simVars.intConstVars, memo),
        boolConstVars                     = SimVar.convertListMemo(simVars.boolConstVars, memo),
        stringConstVars                   = SimVar.convertListMemo(simVars.stringConstVars, memo),
        jacobianVars                      = SimVar.convertListMemo(simVars.jacobianVars, memo),
        seedVars                          = SimVar.convertListMemo(simVars.seedVars, memo),
        realOptimizeConstraintsVars       = SimVar.convertListMemo(simVars.realOptimizeConstraintsVars, memo),
        realOptimizeFinalConstraintsVars  = SimVar.convertListMemo(simVars.realOptimizeFinalConstraintsVars, memo),
        sensitivityVars                   = SimVar.convertListMemo(simVars.sensitivityVars, memo),
        dataReconSetcVars                 = SimVar.convertListMemo(simVars.dataReconSetcVars, memo),
        dataReconinputVars                = SimVar.convertListMemo(simVars.dataReconinputVars, memo),
        dataReconSetBVars                 = SimVar.convertListMemo(simVars.dataReconSetBVars, memo));
    end convert;

    function createSimVarLists
      "creates a list of simvar lists. SplitType.NONE always returns a list with only
      one list as its element and SplitType.TYPE returns a list with four lists."
      input VariablePointers vars;
      output list<list<SimVar>> simVars = {};
      input output SimCode.SimCodeIndices simCodeIndices;
      input SplitType splitType;
      input VarType varType;
    protected
      // scalarize goes through fromList, whose cref dedupe a record and its elements rely on
      list<Pointer<Variable>> sim_vars = VariablePointers.toList(if Flags.getConfigBool(Flags.SIM_CODE_SCALARIZE) then VariablePointers.scalarize(vars) else vars);
      list<SimVar> lst;
    algorithm

      if splitType == SplitType.NONE then
        (lst, simCodeIndices) := SimVar.createList(sim_vars, varType, simCodeIndices);
        simVars := {lst};
      elseif splitType == SplitType.TYPE then
        (simVars, simCodeIndices) := SimVar.createListsByType(sim_vars, varType, simCodeIndices);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of invalid splitType."});
      end if;
    end createSimVarLists;

    function getPartitionVars
      input Partition partition;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      output list<SimVar> part_vars;
    algorithm
      part_vars := match partition.strongComponents
          local
            array<StrongComponent> comps;
            list<list<SimVar>> result = {};

          case SOME(comps) algorithm
            for i in 1:arrayLength(comps) loop
              result := getStrongComponentVars(comps[i], simcode_map) :: result;
            end for;
          then List.flatten(result);

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + Partition.Partition.toString(partition)});
          then fail();
        end match;
    end getPartitionVars;

    function getStrongComponentVars
      input StrongComponent comp;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      output list<SimVar> part_vars = {};
    algorithm
      part_vars := match comp
        case StrongComponent.SINGLE_COMPONENT()     then getVars(comp.var, simcode_map);
        case StrongComponent.MULTI_COMPONENT()      then List.flatten(list(getVars(Slice.getT(v), simcode_map) for v in comp.vars));
        case StrongComponent.SLICED_COMPONENT()     then getVars(Slice.getT(comp.var), simcode_map);
        case StrongComponent.RESIZABLE_COMPONENT()  then getVars(Slice.getT(comp.var), simcode_map);
        case StrongComponent.GENERIC_COMPONENT()    then getVars(BVariable.getVarPointer(comp.var_cref, sourceInfo()), simcode_map);
        case StrongComponent.ENTWINED_COMPONENT()   then List.flatten(list(getStrongComponentVars(c, simcode_map) for c in comp.entwined_slices));
        case StrongComponent.ALGEBRAIC_LOOP()       then List.flatten(list(getVars(Slice.getT(v), simcode_map) for v in comp.strict.iteration_vars));
        case StrongComponent.ALIAS()                then getStrongComponentVars(comp.original, simcode_map);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with unknown reason for\n" + StrongComponent.toString(comp)});
        then fail();
      end match;
    end getStrongComponentVars;

  public
    function numScalarElems
      "Total scalar element count across a list of SimVars, independent of the
       codegen target.  Unlike listScalarSize, always returns the product of
       dimension sizes (not listLength).  Used by NBackEnd Jacobian generation
       to compute the correct number of columns/rows when --simCodeScalarize=false
       yields array SimVars (e.g. x[100] is one SimVar with numArrayElement=[100])."
      input list<SimVar> vars;
      output Integer n;
    algorithm
      n := sum(product(Expression.integerValueOrDefault(e, 1) for e in v.numArrayElement) for v in vars);
    end numScalarElems;

  protected
    function getVars
      input Pointer<Variable> var;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      output list<SimVar> vars = {};
    algorithm
      if Flags.getConfigBool(Flags.SIM_CODE_SCALARIZE) then
        vars := list(UnorderedMap.getSafe(BVariable.getVarName(v), simcode_map, sourceInfo()) for v in VariablePointers.scalarizeList({var}));
      else
        vars := {UnorderedMap.getSafe(BVariable.getVarName(var), simcode_map, sourceInfo())};
      end if;
    end getVars;

  end SimVars;

  constant SimVars emptySimVars = SIMVARS(
    {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
    {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {});

  type SplitType  = enumeration(NONE, TYPE);
  type VarType    = enumeration(SIMULATION, PARAMETER, ALIAS, RESIDUAL, EXTERNAL_OBJECT); // ToDo: PRE, OLD, RELATIONS...

  uniontype VarInfo
    record VAR_INFO
      Integer numZeroCrossings;
      Integer numTimeEvents;
      Integer numRelations;
      Integer numMathEventFunctions;
      Integer numStateVars;
      Integer numAlgVars;
      Integer numDiscreteReal;
      Integer numIntAlgVars;
      Integer numBoolAlgVars;
      Integer numAlgAliasVars;
      Integer numIntAliasVars;
      Integer numBoolAliasVars;
      Integer numParams;
      Integer numIntParams;
      Integer numBoolParams;
      Integer numOutVars;
      Integer numInVars;
      Integer numExternalObjects;
      Integer numStringAlgVars;
      Integer numStringParamVars;
      Integer numStringAliasVars;
      Integer numEquations;
      Integer numLinearSystems;
      Integer numNonLinearSystems;
      Integer numMixedSystems;
      Integer numStateSets;
      Integer numJacobians;
      Integer numOptimizeConstraints;
      Integer numOptimizeFinalConstraints;
      Integer numSensitivityParameters;
      Integer numSetcVars;
      Integer numDataReconVars;
      Integer numRealIntputVars;
      Integer numSetbVars;
      Integer numRelatedBoundaryConditions;
    end VAR_INFO;

    function listScalarSize
      "Var-vector size for a simvar list. The C++ target keeps arrays un-expanded
       but sizes its var vectors and value references per scalar element, so the
       array sizes are summed. Every other target (notably the C runtime, which
       also supports simCodeScalarize=false) keeps one slot per simvar."
      input list<SimVar> vars;
      output Integer sz;
    algorithm
      if stringEqual(Config.simCodeTarget(), "Cpp") then
        sz := sum(product(Expression.integerValueOrDefault(e, 1) for e in v.numArrayElement) for v in vars);
      else
        sz := listLength(vars);
      end if;
    end listScalarSize;

    function create
      input SimVars vars;
      input EventInfo eventInfo;
      input SimCodeIndices simCodeIndices;
      output VarInfo varInfo;
    algorithm
      varInfo := VAR_INFO(
        numZeroCrossings             = sum(Condition.size(cond) for cond in UnorderedMap.keyList(eventInfo.state_map)),
        numTimeEvents                = UnorderedSet.size(eventInfo.time_set),
        numRelations                 = sum(Condition.size(cond) for cond in UnorderedMap.keyList(eventInfo.state_map)),
        numMathEventFunctions        = eventInfo.numberMathEvents,
        numStateVars                 = listScalarSize(vars.stateVars),
        numAlgVars                   = listScalarSize(vars.algVars),
        numDiscreteReal              = listScalarSize(vars.discreteAlgVars),
        numIntAlgVars                = listScalarSize(vars.intAlgVars),
        numBoolAlgVars               = listScalarSize(vars.boolAlgVars),
        numAlgAliasVars              = listScalarSize(vars.aliasVars),
        numIntAliasVars              = listScalarSize(vars.intAliasVars),
        numBoolAliasVars             = listScalarSize(vars.boolAliasVars),
        numParams                    = listScalarSize(vars.paramVars),
        numIntParams                 = listScalarSize(vars.intParamVars),
        numBoolParams                = listScalarSize(vars.boolParamVars),
        numOutVars                   = listLength(vars.outputVars),
        numInVars                    = listLength(vars.inputVars),
        numExternalObjects           = listLength(vars.extObjVars),
        numStringAlgVars             = listScalarSize(vars.stringAlgVars),
        numStringParamVars           = listScalarSize(vars.stringParamVars),
        numStringAliasVars           = listScalarSize(vars.stringAliasVars),
        numEquations                 = simCodeIndices.equationIndex,
        numLinearSystems             = simCodeIndices.linearSystemIndex,
        numNonLinearSystems          = simCodeIndices.nonlinearSystemIndex,
        numMixedSystems              = 0,
        numStateSets                 = 0,
        numJacobians                 = simCodeIndices.nonlinearSystemIndex + simCodeIndices.linearSystemIndex + 5, // #nonlinSystems + #linSystems (torn linear systems with a symbolic Jacobian consume a jacobianIndex slot from the same analyticJacobians array too) + 5 simulation jacs (add state sets later!)
        numOptimizeConstraints       = 0,
        numOptimizeFinalConstraints  = 0,
        numSensitivityParameters     = 0,
        numSetcVars                  = 0,
        numDataReconVars             = 0,
        numRealIntputVars            = 0,
        numSetbVars                  = 0,
        numRelatedBoundaryConditions = 0);
    end create;

    function convert
      input VarInfo varInfo;
      output OldSimCode.VarInfo oldVarInfo;
    algorithm
      oldVarInfo := OldSimCode.VARINFO(
        numZeroCrossings             = varInfo.numZeroCrossings,
        numTimeEvents                = varInfo.numTimeEvents,
        numRelations                 = varInfo.numRelations,
        numMathEventFunctions        = varInfo.numMathEventFunctions,
        numStateVars                 = varInfo.numStateVars,
        numAlgVars                   = varInfo.numAlgVars,
        numDiscreteReal              = varInfo.numDiscreteReal,
        numIntAlgVars                = varInfo.numIntAlgVars,
        numBoolAlgVars               = varInfo.numBoolAlgVars,
        numAlgAliasVars              = varInfo.numAlgAliasVars,
        numIntAliasVars              = varInfo.numIntAliasVars,
        numBoolAliasVars             = varInfo.numBoolAliasVars,
        numParams                    = varInfo.numParams,
        numIntParams                 = varInfo.numIntParams,
        numBoolParams                = varInfo.numBoolParams,
        numOutVars                   = varInfo.numOutVars,
        numInVars                    = varInfo.numInVars,
        numExternalObjects           = varInfo.numExternalObjects,
        numStringAlgVars             = varInfo.numStringAlgVars,
        numStringParamVars           = varInfo.numStringParamVars,
        numStringAliasVars           = varInfo.numStringAliasVars,
        numEquations                 = varInfo.numEquations,
        numLinearSystems             = varInfo.numLinearSystems,
        numNonLinearSystems          = varInfo.numNonLinearSystems,
        numMixedSystems              = varInfo.numMixedSystems,
        numStateSets                 = varInfo.numStateSets,
        numJacobians                 = varInfo.numJacobians,
        numOptimizeConstraints       = varInfo.numOptimizeConstraints,
        numOptimizeFinalConstraints  = varInfo.numOptimizeFinalConstraints,
        numSensitivityParameters     = varInfo.numSensitivityParameters,
        numSetcVars                  = varInfo.numSetcVars,
        numDataReconVars             = varInfo.numDataReconVars,
        numRealInputVars             = varInfo.numRealIntputVars,
        numSetbVars                  = varInfo.numSetbVars,
        numRelatedBoundaryConditions = varInfo.numRelatedBoundaryConditions);
    end convert;
  end VarInfo;

  uniontype ExtObjInfo
    record EXT_OBJ_INFO
      list<SimVar> objects;
      list<tuple<ComponentRef, ComponentRef>> aliases;
    end EXT_OBJ_INFO;


    function toString
      input ExtObjInfo info;
      output String str = SimVar.listToString(info.objects, "External Objects");
    end toString;

    function create
      input VariablePointers external_objects;
      output ExtObjInfo info;
      input output SimVars vars;
      input output SimCodeIndices simCodeIndices;
    protected
      list<SimVar> var_lst;
    algorithm
      (var_lst, simCodeIndices) := SimVar.createList(VariablePointers.toList(external_objects), VarType.EXTERNAL_OBJECT, simCodeIndices);
      vars.extObjVars := var_lst;
      // todo: alias
      info := EXT_OBJ_INFO(var_lst, {});
    end create;

    function convert
      input ExtObjInfo info;
      output OldSimCode.ExtObjInfo oldInfo;
    algorithm
      oldInfo := OldSimCode.EXTOBJINFO(SimVar.convertList(info.objects), {});
    end convert;
  end ExtObjInfo;

  annotation(__OpenModelica_Interface="nbackend");
end NSimVar;
