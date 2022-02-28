/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
  import BackendExtension = NFBackendExtension;
  import Binding = NFBinding;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Operator = NFOperator;
  import Prefixes = NFPrefixes;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;
  import NBVariable.VariablePointers;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // Backend imports
  import BVariable = NBVariable;

  // Old Simcode imports
  import OldSimCodeVar = SimCodeVar;

  // SimCode imports
  import SimCode = NSimCode;

  // Util imports
  import Error;
  import Pointer;
  import StringUtil;
  import Util;

public
  uniontype SimVar "Information about a variable in a Modelica model."
    record SIMVAR
      ComponentRef name;
      BackendExtension.VariableKind varKind;
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
      list<String> numArrayElement;
      Boolean isValueChangeable;
      Boolean isProtected;
      Boolean hideResult;
      Option<array<Integer>> inputIndex;
      Option<String> matrixName "if the varibale is a jacobian var, this is the corresponding matrix";
      Option<Variability> variability "FMI-2.0 variabilty attribute";
      Option<Initial> initial_ "FMI-2.0 initial attribute";
      Option<ComponentRef> exportVar "variables will only be exported to the modelDescription.xml if this attribute is SOME(cref) and this cref is only used in ModelDescription.xml for FMI-2.0 export";
    end SIMVAR;

    function toString
      input SimVar var;
      input output String str = "";
    protected
      Expression start;
    algorithm
      str := str + "(" + intString(var.index) + ")" + BackendExtension.VariableKind.toString(var.varKind) + " (" + intString(SimVar.size(var)) + ") " + Type.toString(var.type_) + " " + ComponentRef.toString(var.name);
      if Util.isSome(var.start) then
        start := Util.getOption(var.start);
        str := str + " = " + Expression.toString(start);
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
          BackendExtension.VariableKind varKind;
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
            numArrayElement     = {},
            isValueChangeable   = isValueChangeable,
            isProtected         = isProtected,
            hideResult          = false,
            inputIndex          = NONE(),
            matrixName          = NONE(),
            variability         = NONE(),
            initial_            = NONE(),
            exportVar           = NONE()
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
      _ := match varType

        case VarType.SIMULATION algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.realVarIndex) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.realVarIndex := simCodeIndices.realVarIndex +1;
        then ();

        case VarType.PARAMETER algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.realParamIndex) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.realParamIndex := simCodeIndices.realParamIndex +1;
        then ();

        case VarType.ALIAS algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.realAliasIndex, Alias.fromBinding(var.binding)) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.realAliasIndex := simCodeIndices.realAliasIndex +1;
        then ();

        case VarType.RESIDUAL algorithm
          Pointer.update(acc, create(var, simCodeIndices.uniqueIndex, simCodeIndices.residualIndex) :: Pointer.access(acc));
          simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
          simCodeIndices.residualIndex := simCodeIndices.residualIndex +1;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable " + ComponentRef.toString(var.name) + "."});
        then fail();

      end match;
      Pointer.update(indices_ptr, simCodeIndices);
    end traverseCreate;

    function size
      input SimVar var;
      output Integer s = Type.sizeOf(var.type_);
    end size;

    function getName
      input SimVar var;
      output ComponentRef name = var.name;
    end getName;

    function getIndex
      input SimVar var;
      output Integer index = var.index;
    end getIndex;

    function convert
      input SimVar simVar;
      output OldSimCodeVar.SimVar oldSimVar;
    algorithm
      oldSimVar := OldSimCodeVar.SIMVAR(
        name                = ComponentRef.toDAE(simVar.name),
        varKind             = convertVarKind(simVar.varKind),
        comment             = simVar.comment,
        unit                = simVar.unit,
        displayUnit         = simVar.displayUnit,
        index               = simVar.index,
        minValue            = if isSome(simVar.min) then SOME(Expression.toDAE(Util.getOption(simVar.min))) else NONE(),
        maxValue            = if isSome(simVar.max) then SOME(Expression.toDAE(Util.getOption(simVar.max))) else NONE(),
        initialValue        = if isSome(simVar.start) then SOME(Expression.toDAE(Util.getOption(simVar.start))) else NONE(),
        nominalValue        = if isSome(simVar.nominal) then SOME(Expression.toDAE(Util.getOption(simVar.nominal))) else NONE(),
        isFixed             = simVar.isFixed,
        type_               = Type.toDAE(simVar.type_),
        isDiscrete          = simVar.isDiscrete,
        arrayCref           = if isSome(simVar.arrayCref) then SOME(ComponentRef.toDAE(Util.getOption(simVar.arrayCref))) else NONE(),
        aliasvar            = Alias.convert(simVar.aliasvar),
        source              = DAE.emptyElementSource, //ToDo update this!
        causality           = NONE(),  //ToDo update this!
        variable_index      = simVar.variable_index,
        fmi_index           = simVar.fmi_index,
        numArrayElement     = simVar.numArrayElement,
        isValueChangeable   = simVar.isValueChangeable,
        isProtected         = simVar.isProtected,
        hideResult          = SOME(simVar.hideResult),
        inputIndex          = simVar.inputIndex,
        matrixName          = simVar.matrixName,
        variability         = NONE(),  //ToDo update this!
        initial_            = NONE(),  //ToDo update this!
        exportVar           = if isSome(simVar.exportVar) then SOME(ComponentRef.toDAE(Util.getOption(simVar.exportVar))) else NONE());
    end convert;

    function convertList
      input list<SimVar> simVar_lst;
      output list<OldSimCodeVar.SimVar> oldSimVar_lst = {};
    algorithm
      for simVar in listReverse(simVar_lst) loop
        oldSimVar_lst := convert(simVar) :: oldSimVar_lst;
      end for;
    end convertList;

  protected
    function parseAttributes
      input BackendExtension.BackendInfo backendInfo;
      output BackendExtension.VariableKind varKind;
      output String unit = "";
      output String displayUnit = "";
      output Option<Expression> min = NONE();
      output Option<Expression> max = NONE();
      output Option<Expression> start = NONE();
      output Option<Expression> nominal = NONE();
      output Boolean isFixed = false;
      output Boolean isDiscrete = false;
      output Boolean isProtected = false;
    algorithm
      _ := match backendInfo
        local
          BackendExtension.VariableAttributes varAttr;

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = varAttr as BackendExtension.VAR_ATTR_REAL())
          algorithm
            if isSome(varAttr.unit) then
              unit := Expression.stringValue(Util.getOption(varAttr.unit));
            end if;
            if isSome(varAttr.displayUnit) then
              displayUnit := Expression.stringValue(Util.getOption(varAttr.displayUnit));
            end if;
            min := varAttr.min;
            max := varAttr.max;
            start := varAttr.start;
            nominal := varAttr.nominal;
            if isSome(varAttr.fixed) then
              isFixed := Expression.booleanValue(Util.getOption(varAttr.fixed));
            end if;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = varAttr as BackendExtension.VAR_ATTR_INT())
          algorithm
            min := varAttr.min;
            max := varAttr.max;
            start := varAttr.start;
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = varAttr as BackendExtension.VAR_ATTR_BOOL())
          algorithm
            start := varAttr.start;
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = varAttr as BackendExtension.VAR_ATTR_CLOCK())
          algorithm
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = varAttr as BackendExtension.VAR_ATTR_STRING())
          algorithm
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = varAttr as BackendExtension.VAR_ATTR_ENUMERATION())
          algorithm
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the BackendInfo could not be parsed."});
        then fail();
      end match;
      isDiscrete := match varKind
        case BackendExtension.DISCRETE()        then true;
        case BackendExtension.DISCRETE_STATE()  then true;
        case BackendExtension.PREVIOUS()        then true;
        case BackendExtension.PARAMETER()       then true;
        case BackendExtension.CONSTANT()        then true;
        case BackendExtension.START()           then true;
                                                else false;
      end match;
    end parseAttributes;

    function parseComment
      input Option<SCode.Comment> absynComment;
      output String commentStr;
    algorithm
      commentStr := match (absynComment)
        case (SOME(SCode.COMMENT(_, SOME(commentStr)))) then commentStr;
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
          backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER()))
        then (SOME(bindingExp), true, Causality.PARAMETER);

        // 2. just like 1. - FLAT_BINDING gets introduced by expanding/scalarizing
        case Variable.VARIABLE(binding = Binding.FLAT_BINDING(variability = NFPrefixes.Variability.CONSTANT, bindingExp = bindingExp),
          backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER()))
        then (SOME(bindingExp), true, Causality.PARAMETER);

        // 3. parameter with non constant binding -> normal start value. Value cannot be changed after simulation
        case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER()))
        then (start, false, Causality.CALCULATED_PARAMETER);

        // 0. other variables -> regular start value and it can be changed after simulation
        else (start, false, Causality.LOCAL);

        // ToDo: more cases!
      end match;
    end parseBinding;

    function convertVarKind
      "Usually this function would belong to NFBackendExtension, but we want to
      avoid Frontend -> Backend dependency."
      input BackendExtension.VariableKind varKind;
      output OldBackendDAE.VarKind oldVarKind;
    algorithm
      oldVarKind := match varKind
        local
          BackendExtension.VariableKind qual;
          Variable var;
          Option<DAE.ComponentRef> oldCrefOpt;
          DAE.ComponentRef oldCref;

        case BackendExtension.ALGEBRAIC()               then OldBackendDAE.VARIABLE();
        case qual as BackendExtension.STATE()
          algorithm
            if isSome(qual.derivative) then
              var := Pointer.access(Util.getOption(qual.derivative));
              oldCrefOpt := SOME(ComponentRef.toDAE(var.name));
            else
              oldCrefOpt := NONE();
            end if;
        then OldBackendDAE.STATE(qual.index, oldCrefOpt, qual.natural);
        case BackendExtension.STATE_DER()               then OldBackendDAE.STATE_DER();
        case BackendExtension.DUMMY_DER()               then OldBackendDAE.DUMMY_DER();
        case BackendExtension.DUMMY_STATE()             then OldBackendDAE.DUMMY_STATE();
        case BackendExtension.DISCRETE()                then OldBackendDAE.DISCRETE();
        case qual as BackendExtension.DISCRETE_STATE()
          algorithm
            var := Pointer.access(qual.previous);
            oldCref := ComponentRef.toDAE(var.name);
        then OldBackendDAE.CLOCKED_STATE(oldCref, qual.fixed);
        case BackendExtension.PREVIOUS()                then OldBackendDAE.DISCRETE();
        case BackendExtension.PARAMETER()               then OldBackendDAE.PARAM();
        case BackendExtension.CONSTANT()                then OldBackendDAE.CONST();
        //ToDo: check this! is this correct? need typechecking?
        case BackendExtension.START()                   then OldBackendDAE.VARIABLE();
        case qual as BackendExtension.EXTOBJ()          then OldBackendDAE.EXTOBJ(qual.fullClassName);
        case BackendExtension.JAC_VAR()                 then OldBackendDAE.JAC_VAR();
        case BackendExtension.JAC_DIFF_VAR()            then OldBackendDAE.JAC_DIFF_VAR();
        case BackendExtension.SEED_VAR()                then OldBackendDAE.SEED_VAR();
        case BackendExtension.OPT_CONSTR()              then OldBackendDAE.OPT_CONSTR();
        case BackendExtension.OPT_FCONSTR()             then OldBackendDAE.OPT_FCONSTR();
        case BackendExtension.OPT_INPUT_WITH_DER()      then OldBackendDAE.OPT_INPUT_WITH_DER();
        case BackendExtension.OPT_INPUT_DER()           then OldBackendDAE.OPT_INPUT_DER();
        case BackendExtension.OPT_TGRID()               then OldBackendDAE.OPT_TGRID();
        case qual as BackendExtension.OPT_LOOP_INPUT()  then OldBackendDAE.OPT_LOOP_INPUT(ComponentRef.toDAE(qual.replaceCref));
        // ToDo maybe deprecated:
        case BackendExtension.ALG_STATE()               then OldBackendDAE.ALG_STATE();
        case BackendExtension.ALG_STATE_OLD()           then OldBackendDAE.ALG_STATE_OLD();
        case BackendExtension.DAE_RESIDUAL_VAR()        then OldBackendDAE.DAE_RESIDUAL_VAR();
        case BackendExtension.DAE_AUX_VAR()             then OldBackendDAE.DAE_AUX_VAR();
        case BackendExtension.LOOP_ITERATION()          then OldBackendDAE.LOOP_ITERATION();
        case BackendExtension.LOOP_SOLVED()             then OldBackendDAE.LOOP_SOLVED();
        case BackendExtension.FRONTEND_DUMMY()
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong VariableKind FRONTEND_DUMMY(). This should not exist after frontend."});
        then fail();
        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unhandled VariableKind " + BackendExtension.VariableKind.toString(varKind) + "."});
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
        local
          Expression exp;
        case Binding.TYPED_BINDING(bindingExp = exp) algorithm
        then getAlias(exp);
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
          Expression e, e1, e2;
          Real gain, offset;
          ComponentRef cref;

        // equality alias
        case e as Expression.CREF()                         then ALIAS(e.cref, 1.0, 0.0);

        // negated alias
        case Expression.UNARY(exp = e as Expression.CREF()) then ALIAS(e.cref, -1.0, 0.0);
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
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> stringAliasVars;
      list<SimVar> extObjVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
      list<SimVar> residualVars;
      list<SimVar> jacobianVars;
      list<SimVar> seedVars;
      list<SimVar> realOptimizeConstraintsVars;
      list<SimVar> realOptimizeFinalConstraintsVars;
      list<SimVar> sensitivityVars "variable used to calculate sensitivities for parameters nSensitivitityParameters + nRealParam*nStates";
      list<SimVar> dataReconSetcVars;
      list<SimVar> dataReconinputVars;
    end SIMVARS;

    function toString
      input SimVars vars;
      input output String str = "";
    algorithm
      str := StringUtil.headline_2("SimVars " + str);
      str := str + SimVar.listToString(vars.stateVars, "States");
      str := str + SimVar.listToString(vars.derivativeVars, "Derivatives");
      str := str + SimVar.listToString(vars.algVars, "Algebraic Variables");
      str := str + SimVar.listToString(vars.paramVars, "Real Parameters");
      str := str + SimVar.listToString(vars.intParamVars, "Integer Parameters");
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
      list<SimVar> discreteAlgVars = {}, intAlgVars = {}, boolAlgVars = {}, stringAlgVars = {};
      list<SimVar> inputVars = {};
      list<SimVar> outputVars = {};
      list<SimVar> aliasVars = {}, intAliasVars = {}, boolAliasVars = {}, stringAliasVars = {};
      list<SimVar> paramVars = {}, intParamVars = {}, boolParamVars = {}, stringParamVars = {};
      list<SimVar> constVars = {}, intConstVars = {}, boolConstVars = {}, stringConstVars = {};
      list<SimVar> extObjVars = {};
      list<SimVar> residualVars = {};
      list<SimVar> jacobianVars = {};
      list<SimVar> seedVars = {};
      list<SimVar> realOptimizeConstraintsVars = {};
      list<SimVar> realOptimizeFinalConstraintsVars = {};
      list<SimVar> sensitivityVars = {};
      list<SimVar> dataReconSetcVars = {};
      list<SimVar> dataReconinputVars = {};
    algorithm
      _ := match varData
        local
          BVariable.VarData qual;

        case qual as BVariable.VAR_DATA_SIM()
          algorithm
            ({stateVars}, simCodeIndices)                                               := createSimVarLists(qual.states, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
            ({derivativeVars}, simCodeIndices)                                          := createSimVarLists(qual.derivatives, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
            ({algVars}, simCodeIndices)                                                 := createSimVarLists(qual.algebraics, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
            ({nonTrivialAlias}, simCodeIndices)                                         := createSimVarLists(qual.nonTrivialAlias, simCodeIndices, SplitType.NONE, VarType.SIMULATION);
            ({discreteAlgVars, intAlgVars, boolAlgVars, stringAlgVars}, simCodeIndices) := createSimVarLists(qual.discretes, simCodeIndices, SplitType.TYPE, VarType.SIMULATION);
            ({aliasVars, intAliasVars, boolAliasVars, stringAliasVars}, simCodeIndices) := createSimVarLists(qual.aliasVars, simCodeIndices, SplitType.TYPE, VarType.ALIAS);
            ({paramVars, intParamVars, boolParamVars, stringParamVars}, simCodeIndices) := createSimVarLists(qual.parameters, simCodeIndices, SplitType.TYPE, VarType.PARAMETER);
            ({constVars, intConstVars, boolConstVars, stringConstVars}, simCodeIndices) := createSimVarLists(qual.constants, simCodeIndices, SplitType.TYPE, VarType.SIMULATION);
            ({residualVars}, simCodeIndices)                                            := createSimVarLists(residual_vars, simCodeIndices, SplitType.NONE, VarType.RESIDUAL);
        then ();

        case qual as BVariable.VAR_DATA_JAC() then ();
        case qual as BVariable.VAR_DATA_HES() then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;

      simVars := SIMVARS(
        stateVars                           = stateVars,
        derivativeVars                      = derivativeVars,
        algVars                             = listAppend(algVars, nonTrivialAlias),
        discreteAlgVars                     = discreteAlgVars,
        intAlgVars                          = intAlgVars,
        boolAlgVars                         = boolAlgVars,
        inputVars                           = inputVars,
        outputVars                          = outputVars,
        aliasVars                           = aliasVars,
        intAliasVars                        = intAliasVars,
        boolAliasVars                       = boolAliasVars,
        paramVars                           = paramVars,
        intParamVars                        = intParamVars,
        boolParamVars                       = boolParamVars,
        stringAlgVars                       = stringAlgVars,
        stringParamVars                     = stringParamVars,
        stringAliasVars                     = stringAliasVars,
        extObjVars                          = extObjVars,
        constVars                           = constVars,
        intConstVars                        = intConstVars,
        boolConstVars                       = boolConstVars,
        stringConstVars                     = stringConstVars,
        residualVars                        = residualVars,
        jacobianVars                        = jacobianVars,
        seedVars                            = seedVars,
        realOptimizeConstraintsVars         = realOptimizeConstraintsVars,
        realOptimizeFinalConstraintsVars    = realOptimizeFinalConstraintsVars,
        sensitivityVars                     = sensitivityVars,
        dataReconSetcVars                   = dataReconSetcVars,
        dataReconinputVars                  = dataReconinputVars
      );
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
        if BVariable.checkCref(cref, BVariable.isSeed) then
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
                          + listLength(simVars.dataReconinputVars);
    end size;

    function convert
      input SimVars simVars;
      output OldSimCodeVar.SimVars oldSimVars;
    algorithm
      oldSimVars := OldSimCodeVar.SIMVARS(
        stateVars                         = SimVar.convertList(simVars.stateVars),
        derivativeVars                    = SimVar.convertList(simVars.derivativeVars),
        algVars                           = SimVar.convertList(simVars.algVars),
        discreteAlgVars                   = SimVar.convertList(simVars.discreteAlgVars),
        intAlgVars                        = SimVar.convertList(simVars.intAlgVars),
        boolAlgVars                       = SimVar.convertList(simVars.boolAlgVars),
        inputVars                         = SimVar.convertList(simVars.inputVars),
        outputVars                        = SimVar.convertList(simVars.outputVars),
        aliasVars                         = SimVar.convertList(simVars.aliasVars),
        intAliasVars                      = SimVar.convertList(simVars.intAliasVars),
        boolAliasVars                     = SimVar.convertList(simVars.boolAliasVars),
        paramVars                         = SimVar.convertList(simVars.paramVars),
        intParamVars                      = SimVar.convertList(simVars.intParamVars),
        boolParamVars                     = SimVar.convertList(simVars.boolParamVars),
        stringAlgVars                     = SimVar.convertList(simVars.stringAlgVars),
        stringParamVars                   = SimVar.convertList(simVars.stringParamVars),
        stringAliasVars                   = SimVar.convertList(simVars.stringAliasVars),
        extObjVars                        = SimVar.convertList(simVars.extObjVars),
        constVars                         = SimVar.convertList(simVars.constVars),
        intConstVars                      = SimVar.convertList(simVars.intConstVars),
        boolConstVars                     = SimVar.convertList(simVars.boolConstVars),
        stringConstVars                   = SimVar.convertList(simVars.stringConstVars),
        jacobianVars                      = SimVar.convertList(simVars.jacobianVars),
        seedVars                          = SimVar.convertList(simVars.seedVars),
        realOptimizeConstraintsVars       = SimVar.convertList(simVars.realOptimizeConstraintsVars),
        realOptimizeFinalConstraintsVars  = SimVar.convertList(simVars.realOptimizeFinalConstraintsVars),
        sensitivityVars                   = SimVar.convertList(simVars.sensitivityVars),
        dataReconSetcVars                 = SimVar.convertList(simVars.dataReconSetcVars),
        dataReconinputVars                = SimVar.convertList(simVars.dataReconinputVars));
    end convert;

    function createSimVarLists
      "creates a list of simvar lists. SplitType.NONE always returns a list with only
      one list as its element and SplitType.TYPE returns a list with four lists."
      input VariablePointers vars;
      output list<list<SimVar>> simVars = {};
      input output SimCode.SimCodeIndices simCodeIndices;
      input SplitType splitType = SplitType.NONE;
      input VarType varType = VarType.SIMULATION;
    protected
      VariablePointers scalar_vars;
      Pointer<list<SimVar>> acc = Pointer.create({});
      Pointer<list<SimVar>> real_lst = Pointer.create({});
      Pointer<list<SimVar>> int_lst = Pointer.create({});
      Pointer<list<SimVar>> bool_lst = Pointer.create({});
      Pointer<list<SimVar>> string_lst = Pointer.create({});
      Pointer<SimCode.SimCodeIndices> indices_ptr = Pointer.create(simCodeIndices);
    algorithm
      // scalarize variables for simcode
      scalar_vars := VariablePointers.scalarize(vars);
      if splitType == SplitType.NONE then
        // Do not split and return everything as one single list
        VariablePointers.map(scalar_vars, function SimVar.traverseCreate(acc = acc, indices_ptr = indices_ptr, varType = varType));
        simVars := {listReverse(Pointer.access(acc))};
        simCodeIndices := Pointer.access(indices_ptr);
      elseif splitType == SplitType.TYPE then
        // Split the variables by basic type (real, integer, boolean, string)
        // and return a list for each type
        VariablePointers.map(scalar_vars, function splitByType(real_lst = real_lst, int_lst = int_lst, bool_lst = bool_lst, string_lst = string_lst, indices_ptr = indices_ptr, varType = varType));
        simVars := {listReverse(Pointer.access(real_lst)),
                    listReverse(Pointer.access(int_lst)),
                    listReverse(Pointer.access(bool_lst)),
                    listReverse(Pointer.access(string_lst))};
        simCodeIndices := Pointer.access(indices_ptr);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of invalid splitType."});
      end if;
    end createSimVarLists;

    function splitByType
      "Traverser function for splitting process. Target for SplitType.TYPE"
      input output Variable var;
      input Pointer<list<SimVar>> real_lst;
      input Pointer<list<SimVar>> int_lst;
      input Pointer<list<SimVar>> bool_lst;
      input Pointer<list<SimVar>> string_lst;
      input Pointer<SimCode.SimCodeIndices> indices_ptr;
      input VarType varType;
    protected
      SimCode.SimCodeIndices simCodeIndices = Pointer.access(indices_ptr);
    algorithm
      _ := match (var.ty, varType)

        case (Type.REAL(), VarType.SIMULATION)
          algorithm
            Pointer.update(real_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.realVarIndex) :: Pointer.access(real_lst));
            simCodeIndices.realVarIndex := simCodeIndices.realVarIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.INTEGER(), VarType.SIMULATION)
          algorithm
            Pointer.update(int_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.integerVarIndex) :: Pointer.access(int_lst));
            simCodeIndices.integerVarIndex := simCodeIndices.integerVarIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.BOOLEAN(), VarType.SIMULATION)
          algorithm
            Pointer.update(bool_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.booleanVarIndex) :: Pointer.access(bool_lst));
            simCodeIndices.booleanVarIndex := simCodeIndices.booleanVarIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.STRING(), VarType.SIMULATION)
          algorithm
            Pointer.update(string_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.stringVarIndex) :: Pointer.access(string_lst));
            simCodeIndices.stringVarIndex := simCodeIndices.stringVarIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.REAL(), VarType.PARAMETER)
          algorithm
            Pointer.update(real_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.realParamIndex) :: Pointer.access(real_lst));
            simCodeIndices.realParamIndex := simCodeIndices.realParamIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.INTEGER(), VarType.PARAMETER)
          algorithm
            Pointer.update(int_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.integerParamIndex) :: Pointer.access(int_lst));
            simCodeIndices.integerParamIndex := simCodeIndices.integerParamIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.BOOLEAN(), VarType.PARAMETER)
          algorithm
            Pointer.update(bool_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.booleanParamIndex) :: Pointer.access(bool_lst));
            simCodeIndices.booleanParamIndex := simCodeIndices.booleanParamIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.STRING(), VarType.PARAMETER)
          algorithm
            Pointer.update(string_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.stringParamIndex) :: Pointer.access(string_lst));
            simCodeIndices.stringParamIndex := simCodeIndices.stringParamIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.REAL(), VarType.ALIAS)
          algorithm
            Pointer.update(real_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.realAliasIndex, Alias.fromBinding(var.binding)) :: Pointer.access(real_lst));
            simCodeIndices.realAliasIndex := simCodeIndices.realAliasIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.INTEGER(), VarType.ALIAS)
          algorithm
            Pointer.update(int_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.integerAliasIndex, Alias.fromBinding(var.binding)) :: Pointer.access(int_lst));
            simCodeIndices.integerAliasIndex := simCodeIndices.integerAliasIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.BOOLEAN(), VarType.ALIAS)
          algorithm
            Pointer.update(bool_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.booleanAliasIndex, Alias.fromBinding(var.binding)) :: Pointer.access(bool_lst));
            simCodeIndices.booleanAliasIndex := simCodeIndices.booleanAliasIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        case (Type.STRING(), VarType.ALIAS)
          algorithm
            Pointer.update(string_lst, SimVar.create(var, simCodeIndices.uniqueIndex, simCodeIndices.stringAliasIndex, Alias.fromBinding(var.binding)) :: Pointer.access(string_lst));
            simCodeIndices.stringAliasIndex := simCodeIndices.stringAliasIndex + 1;
            simCodeIndices.uniqueIndex := simCodeIndices.uniqueIndex + 1;
            Pointer.update(indices_ptr, simCodeIndices);
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unhandled Variable " + ComponentRef.toString(var.name) + "."});
        then fail();

      end match;
    end splitByType;

  end SimVars;

  constant SimVars emptySimVars = SIMVARS({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
   {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {});

  type SplitType  = enumeration(NONE, TYPE);
  type VarType    = enumeration(SIMULATION, PARAMETER, ALIAS, RESIDUAL); // ToDo: PRE, OLD, RELATIONS...

  annotation(__OpenModelica_Interface="backend");
end NSimVar;
