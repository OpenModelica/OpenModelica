/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2020, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
encapsulated package NFBackendExtension
  " ==========================================================================
    kabdelhak: The following structures are used only in the backend to avoid a
    forward dependency of the frontend to the backend. All functions for these
    structures are defined in NBVariable.mo
  ========================================================================== "

protected
  // OF imports
  import Absyn;
  import AbsynUtil;
  import DAE;
  import Dump;
  import SCode;
  import SCodeUtil;

  //NF imports
  import Attributes = NFAttributes;
  import NFBinding.Binding;
  import Call = NFCall;
  import Ceval = NFCeval;
  import ComplexType = NFComplexType;
  import NFComponent.Component;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import ExpressionIterator = NFExpressionIterator;
  import NFFunction.Function;
  import NFPrefixes.{Direction, Variability};
  import NFInstNode.InstNode;
  import Type = NFType;
  import Variable = NFVariable;

  // Util imports
  import Pointer;
  import UnorderedMap;

public
  uniontype BackendInfo
    record BACKEND_INFO
      VariableKind varKind                "Structural kind: state, algebraic...";
      VariableAttributes attributes       "values on built-in attributes";
      Annotations annotations             "values on annotations (vendor specific)";
      Option<Pointer<Variable>> var_pre   "Pointer (var -> pre) or (pre -> var) if existent.";
      Option<Pointer<Variable>> var_seed  "Pointer (var -> seed) or (seed -> var) if existent.";
      Option<Pointer<Variable>> var_pder  "Pointer (var -> pder) or (pder -> var) if existent.";
      Option<Pointer<Variable>> parent    "record parent if it is part of a record.";
    end BACKEND_INFO;

    function toString
      input BackendInfo backendInfo;
      output String str;
    algorithm
      str := VariableAttributes.toString(backendInfo.attributes);
      str := VariableKind.toString(backendInfo.varKind) + (if str == "" then "" else " " + str);
    end toString;

    function map
      input output BackendInfo binfo;
      input expFunc func;
      partial function expFunc
        input output Expression exp;
      end expFunc;
    algorithm
      binfo.attributes := VariableAttributes.map(binfo.attributes, func);
    end map;

    function getVarKind
      input BackendInfo binfo;
      output VariableKind varKind = binfo.varKind;
    end getVarKind;

    function setVarKind
      input output BackendInfo binfo;
      input VariableKind varKind;
    algorithm
      binfo.varKind := varKind;
    end setVarKind;

    function setParent
      input output BackendInfo binfo;
      input Pointer<Variable> parent;
    algorithm
      binfo.parent := SOME(parent);
    end setParent;

    partial function setPartner
      input output BackendInfo binfo;
      input Option<Pointer<Variable>> var_ptr;
    end setPartner;

    function setVarPre extends setPartner;
    algorithm
      binfo.var_pre := var_ptr;
    end setVarPre;

    function setVarSeed extends setPartner;
    algorithm
      binfo.var_seed := var_ptr;
    end setVarSeed;

    function setVarPDer extends setPartner;
    algorithm
      binfo.var_pder := var_ptr;
    end setVarPDer;

    function setAttributes
      input output BackendInfo binfo;
      input VariableAttributes attributes;
      input Annotations annotations;
    algorithm
      binfo.attributes := attributes;
      binfo.annotations := annotations;
    end setAttributes;

    function setHideResult
      input output BackendInfo binfo;
      input Boolean hideResult;
    algorithm
      binfo := match binfo
        local
          Annotations anno;
        case BACKEND_INFO(annotations = anno as ANNOTATIONS()) algorithm
          anno.hideResult := hideResult;
          binfo.annotations := anno;
        then binfo;
        else binfo;
      end match;
    end setHideResult;

    function scalarize
      input BackendInfo binfo;
      input Integer length;
      output list<BackendInfo> binfo_list;
    algorithm
      binfo_list := match binfo.varKind
        local
          list<VariableAttributes> scalar_attributes;
        case VariableKind.FRONTEND_DUMMY() then List.fill(binfo, length);
        else algorithm
          scalar_attributes := VariableAttributes.scalarize(binfo.attributes, length);
        then list(BACKEND_INFO(binfo.varKind, attr, binfo.annotations, binfo.var_pre, binfo.var_seed, binfo.var_pder, binfo.parent) for attr in scalar_attributes);
      end match;
    end scalarize;
  end BackendInfo;

  constant BackendInfo DUMMY_BACKEND_INFO = BackendInfo.BACKEND_INFO(VariableKind.FRONTEND_DUMMY(), EMPTY_VAR_ATTR_REAL, EMPTY_ANNOTATIONS, NONE(), NONE(), NONE(), NONE());

  uniontype VariableKind
    record TIME end TIME;
    record ALGEBRAIC end ALGEBRAIC;
    record STATE
      Integer index                         "how often this states was differentiated";
      Option<Pointer<Variable>> derivative  "pointer to the derivative";
      Boolean natural                       "false if it was forced by StateSelect.always or StateSelect.prefer or generated by index reduction";
    end STATE;
    record STATE_DER
      Pointer<Variable> state               "Original state";
      Option<Pointer<Expression>> alias     "Optional alias state expression. Result of differentiating the state if existant!";
    end STATE_DER;
    record DUMMY_DER
      Pointer<Variable> dummy_state         "corresponding dummy state";
    end DUMMY_DER;
    record DUMMY_STATE
      Pointer<Variable> dummy_der           "corresponding dummy derivative";
    end DUMMY_STATE; // ToDo: maybe dynamic state for dynamic state selection in index reduction
    record DISCRETE end DISCRETE;
    record DISCRETE_STATE end DISCRETE_STATE;
    record PREVIOUS end PREVIOUS;
    record CLOCK end CLOCK;
    record CLOCKED end CLOCKED;
    record PARAMETER
      Option<Integer> resize_value          "if the parameter is resizable, this is the computed optimal size";
    end PARAMETER;
    record CONSTANT end CONSTANT;
    record ITERATOR end ITERATOR;
    record RECORD
      list<Pointer<Variable>> children;
      Boolean known                         "true if the record is known. e.g. parameters";
    end RECORD;
    record START
      Pointer<Variable> original            "Pointer to the corresponding original variable.";
    end START;
    record EXTOBJ
      Absyn.Path fullClassName;
    end EXTOBJ;
    record JAC_VAR end JAC_VAR;
    record JAC_TMP_VAR end JAC_TMP_VAR;
    record SEED_VAR end SEED_VAR;
    record OPT_CONSTR end OPT_CONSTR;
    record OPT_FCONSTR end OPT_FCONSTR;
    record OPT_INPUT_WITH_DER end OPT_INPUT_WITH_DER;
    record OPT_INPUT_DER end OPT_INPUT_DER;
    record OPT_TGRID end OPT_TGRID;
    record OPT_LOOP_INPUT
      ComponentRef replaceCref;
    end OPT_LOOP_INPUT;
    // ToDo maybe deprecated:
    record ALG_STATE        "algebraic state used by inline solver" end ALG_STATE;
    record ALG_STATE_OLD    "algebraic state old value used by inline solver" end ALG_STATE_OLD;
    record RESIDUAL_VAR end RESIDUAL_VAR;
    record DAE_AUX_VAR      "auxiliary variable used for DAEmode" end DAE_AUX_VAR;
    record LOOP_ITERATION   "used in SIMCODE, iteration variables in algebraic loops" end LOOP_ITERATION;
    record LOOP_SOLVED      "used in SIMCODE, inner variables of a torn algebraic loop" end LOOP_SOLVED;
    record FRONTEND_DUMMY   "Undefined variable type. Only to be used during frontend phase." end FRONTEND_DUMMY;

    function toString
      input VariableKind varKind;
      output String str;
    algorithm
      str := match varKind
        case TIME()               then "[TIME]";
        case ALGEBRAIC()          then "[ALGB]";
        case STATE()              then "[STAT]";
        case STATE_DER()          then "[DER-]";
        case DUMMY_DER()          then "[DDER]";
        case DUMMY_STATE()        then "[DSTA]";
        case DISCRETE()           then "[DISC]";
        case DISCRETE_STATE()     then "[DISS]";
        case PREVIOUS()           then "[PRE-]";
        case CLOCK()              then "[CLCK]";
        case CLOCKED()            then "[CLKD]";
        case PARAMETER()          then "[PRMT]";
        case CONSTANT()           then "[CNST]";
        case ITERATOR()           then "[ITER]";
        case RECORD()             then "[RECD]";
        case START()              then "[STRT]";
        case EXTOBJ()             then "[EXTO]";
        case JAC_VAR()            then "[JVAR]";
        case JAC_TMP_VAR()        then "[JTMP]";
        case SEED_VAR()           then "[SEED]";
        case OPT_CONSTR()         then "[OPT][CONS]";
        case OPT_FCONSTR()        then "[OPT][FCON]";
        case OPT_INPUT_WITH_DER() then "[OPT][INWD]";
        case OPT_INPUT_DER()      then "[OPT][INPD]";
        case OPT_TGRID()          then "[OPT][TGRD]";
        case OPT_LOOP_INPUT()     then "[OPT][LOOP]";
        case ALG_STATE()          then "[ASTA]";
        case RESIDUAL_VAR()       then "[RES-]";
        case DAE_AUX_VAR()        then "[AUX-]";
        case LOOP_ITERATION()     then "[LOOP]";
        case LOOP_SOLVED()        then "[INNR]";
        case FRONTEND_DUMMY()     then "[DMMY]";
                                  else "[FAIL] " + getInstanceName() + " failed.";
      end match;
    end toString;

    function isTimeDependent
      input VariableKind varKind;
      output Boolean b;
    algorithm
      // ToDo: check other types!
      b := match varKind
        case PARAMETER()  then false;
        case CONSTANT()   then false;
        case ITERATOR()   then false;
        case START()      then false;
        else true;
      end match;
    end isTimeDependent;

    function fromType
      "only creates record, parameter, discrete or algebraic kind"
      input Type ty;
      input Boolean makeParam;
      output VariableKind varKind;
    algorithm
      if Type.isRecord(Type.arrayElementType(ty)) then
        varKind := RECORD({}, makeParam); // ToDo: children!
      elseif makeParam then
        varKind := PARAMETER(NONE());
      elseif Type.isDiscrete(ty) then
        varKind := DISCRETE();
      else
        varKind := ALGEBRAIC();
      end if;
    end fromType;
  end VariableKind;

  uniontype VariableAttributes
    record VAR_ATTR_REAL
      Option<Expression> quantity             "quantity";
      Option<Expression> unit                 "SI Unit for actual computation value";
      Option<Expression> displayUnit          "SI Unit only for displaying";
      Option<Expression> min                  "Lower boundry";
      Option<Expression> max                  "Upper boundry";
      Option<Expression> start                "start value";
      Option<Expression> fixed                "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Expression> nominal              "nominal";
      Option<StateSelect> stateSelect         "Priority to be selected as a state during index reduction";
      Option<TearingSelect> tearingSelect     "Priority to be selected as an iteration variable during tearing";
      Option<Uncertainty> uncertainty         "Attributes from data reconcilliation";
      Option<Distribution> distribution       "ToDo: ???";
      Option<Expression> binding              "A binding expression for certain types. E.G. parameters";
      Option<Boolean> isProtected             "Defined in protected scope";
      Option<Boolean> finalPrefix             "Defined as final";
      Option<Expression> startOrigin          "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
    end VAR_ATTR_REAL;

    record VAR_ATTR_INT
      Option<Expression> quantity             "quantity";
      Option<Expression> min                  "Lower boundry";
      Option<Expression> max                  "Upper boundry";
      Option<Expression> start                "start value";
      Option<Expression> fixed                "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Uncertainty> uncertainty         "Attributes from data reconcilliation";
      Option<Distribution> distribution       "ToDo: ???";
      Option<Expression> binding              "A binding expression for certain types. E.G. parameters";
      Option<Boolean> isProtected             "Defined in protected scope";
      Option<Boolean> finalPrefix             "Defined as final";
      Option<Expression> startOrigin          "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
    end VAR_ATTR_INT;

    record VAR_ATTR_BOOL
      Option<Expression> quantity             "quantity";
      Option<Expression> start                "start value";
      Option<Expression> fixed                "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Expression> binding              "A binding expression for certain types. E.G. parameters";
      Option<Boolean> isProtected             "Defined in protected scope";
      Option<Boolean> finalPrefix             "Defined as final";
      Option<Expression> startOrigin          "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
    end VAR_ATTR_BOOL;

    record VAR_ATTR_CLOCK
      Option<Boolean> isProtected             "Defined in protected scope";
      Option<Boolean> finalPrefix             "Defined as final";
    end VAR_ATTR_CLOCK;

    record VAR_ATTR_STRING
      "kabdelhak: why does string have quantity/start/fixed?"
      Option<Expression> quantity             "quantity";
      Option<Expression> start                "start value";
      Option<Expression> fixed                "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Expression> binding              "A binding expression for certain types. E.G. parameters";
      Option<Boolean> isProtected             "Defined in protected scope";
      Option<Boolean> finalPrefix             "Defined as final";
      Option<Expression> startOrigin          "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
    end VAR_ATTR_STRING;

    record VAR_ATTR_ENUMERATION
      Option<Expression> quantity             "quantity";
      Option<Expression> min                  "Lower boundry";
      Option<Expression> max                  "Upper boundry";
      Option<Expression> start                "start value";
      Option<Expression> fixed                "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Expression> binding              "A binding expression for certain types. E.G. parameters";
      Option<Boolean> isProtected             "Defined in protected scope";
      Option<Boolean> finalPrefix             "Defined as final";
      Option<Expression> startOrigin          "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
    end VAR_ATTR_ENUMERATION;

    record VAR_ATTR_RECORD
      UnorderedMap<String, Integer> indexMap;
      array<VariableAttributes> childrenAttr;
    end VAR_ATTR_RECORD;

    type VarType = enumeration(ENUMERATION, CLOCK, STRING);

    function toString
      input VariableAttributes attr;
      output String str = "";
    algorithm
      str := match attr
        case VAR_ATTR_REAL()
        then attributesToString({("fixed", attr.fixed), ("start", attr.start), ("min", attr.min), ("max", attr.max), ("nominal", attr.nominal)}, attr.stateSelect, attr.tearingSelect);

        case VAR_ATTR_INT()
        then attributesToString({("fixed", attr.fixed), ("start", attr.start), ("min", attr.min), ("max", attr.max)}, NONE(), NONE());

        case VAR_ATTR_BOOL()
        then attributesToString({("fixed", attr.fixed), ("start", attr.start)}, NONE(), NONE());

        case VAR_ATTR_CLOCK()
        then "";

        case VAR_ATTR_STRING()
        then attributesToString({("fixed", attr.fixed), ("start", attr.start)}, NONE(), NONE());

        case VAR_ATTR_ENUMERATION()
        then attributesToString({("fixed", attr.fixed), ("start", attr.start), ("min", attr.min), ("max", attr.max)}, NONE(), NONE());

        case VAR_ATTR_RECORD()
        then List.toString(UnorderedMap.toList(attr.indexMap), function recordString(childrenAttr = attr.childrenAttr), "", "" ,", " , "");

        else getInstanceName() + " failed. Attribute string could not be created.";
      end match;
      // put the string in parentheses only if it is not empty
      str := if "" == str then "" else "(" + str + ")";
    end toString;

    function recordString
      input tuple<String, Integer> attr_tpl;
      input array<VariableAttributes> childrenAttr;
      output String str;
    protected
      String name;
      Integer index;
    algorithm
      (name, index) := attr_tpl;
      str := name + toString(childrenAttr[index]);
    end recordString;

    function create
      input list<tuple<String, Binding>> attrs;
      input Type ty;
      input Attributes compAttrs;
      input list<Variable> children;
      input Option<SCode.Comment> comment;
      output VariableAttributes attributes;
    protected
      Boolean is_final;
      Type elTy;
      Boolean is_array = false;
      ComplexType complexTy;
    algorithm
      is_final := compAttrs.isFinal or
                  compAttrs.variability == Variability.STRUCTURAL_PARAMETER;

      attributes := match Type.arrayElementType(ty)
        case Type.REAL()        then createReal(attrs, is_final, comment);
        case Type.INTEGER()     then createInt(attrs, is_final);
        case Type.BOOLEAN()     then createBool(attrs, is_final);
        case Type.STRING()      then createString(attrs, is_final);
        case Type.ENUMERATION() then createEnum(attrs, is_final);
        case Type.CLOCK()       then createClock(is_final);
        case Type.COMPLEX(complexTy = complexTy as ComplexType.RECORD())
        then createRecord(attrs, complexTy.indexMap, children, is_final);

        else createReal(attrs, is_final, comment);
      end match;
    end create;

    function map
      input output VariableAttributes attributes;
      input expFunc func;
      partial function expFunc
        input output Expression exp;
      end expFunc;
    algorithm
      attributes := match attributes
        case VAR_ATTR_REAL() algorithm
          attributes.quantity     := Util.applyOption(attributes.quantity, function Expression.map(func = func));
          attributes.unit         := Util.applyOption(attributes.unit, function Expression.map(func = func));
          attributes.displayUnit  := Util.applyOption(attributes.displayUnit, function Expression.map(func = func));
          attributes.min          := Util.applyOption(attributes.min, function Expression.map(func = func));
          attributes.max          := Util.applyOption(attributes.max, function Expression.map(func = func));
          attributes.start        := Util.applyOption(attributes.start, function Expression.map(func = func));
          attributes.fixed        := Util.applyOption(attributes.fixed, function Expression.map(func = func));
          attributes.nominal      := Util.applyOption(attributes.nominal, function Expression.map(func = func));
          attributes.binding      := Util.applyOption(attributes.binding, function Expression.map(func = func));
          attributes.startOrigin  := Util.applyOption(attributes.startOrigin, function Expression.map(func = func));
        then attributes;

        case VAR_ATTR_INT() algorithm
          attributes.quantity     := Util.applyOption(attributes.quantity, function Expression.map(func = func));
          attributes.min          := Util.applyOption(attributes.min, function Expression.map(func = func));
          attributes.max          := Util.applyOption(attributes.max, function Expression.map(func = func));
          attributes.start        := Util.applyOption(attributes.start, function Expression.map(func = func));
          attributes.fixed        := Util.applyOption(attributes.fixed, function Expression.map(func = func));
          attributes.binding      := Util.applyOption(attributes.binding, function Expression.map(func = func));
          attributes.startOrigin  := Util.applyOption(attributes.startOrigin, function Expression.map(func = func));
        then attributes;

        case VAR_ATTR_BOOL() algorithm
          attributes.quantity     := Util.applyOption(attributes.quantity, function Expression.map(func = func));
          attributes.start        := Util.applyOption(attributes.start, function Expression.map(func = func));
          attributes.fixed        := Util.applyOption(attributes.fixed, function Expression.map(func = func));
          attributes.binding      := Util.applyOption(attributes.binding, function Expression.map(func = func));
          attributes.startOrigin  := Util.applyOption(attributes.startOrigin, function Expression.map(func = func));
        then attributes;

        case VAR_ATTR_STRING() algorithm
          attributes.quantity     := Util.applyOption(attributes.quantity, function Expression.map(func = func));
          attributes.start        := Util.applyOption(attributes.start, function Expression.map(func = func));
          attributes.fixed        := Util.applyOption(attributes.fixed, function Expression.map(func = func));
          attributes.binding      := Util.applyOption(attributes.binding, function Expression.map(func = func));
          attributes.startOrigin  := Util.applyOption(attributes.startOrigin, function Expression.map(func = func));
        then attributes;

        case VAR_ATTR_ENUMERATION() algorithm
          attributes.quantity     := Util.applyOption(attributes.quantity, function Expression.map(func = func));
          attributes.min          := Util.applyOption(attributes.min, function Expression.map(func = func));
          attributes.max          := Util.applyOption(attributes.max, function Expression.map(func = func));
          attributes.start        := Util.applyOption(attributes.start, function Expression.map(func = func));
          attributes.fixed        := Util.applyOption(attributes.fixed, function Expression.map(func = func));
          attributes.binding      := Util.applyOption(attributes.binding, function Expression.map(func = func));
          attributes.startOrigin  := Util.applyOption(attributes.startOrigin, function Expression.map(func = func));
        then attributes;

        case VAR_ATTR_RECORD() algorithm
          attributes.childrenAttr := listArray(list(map(attr, func) for attr in attributes.childrenAttr));
        then attributes;

        else attributes;
      end match;
    end map;

    function setFixed
      input output VariableAttributes attributes;
      input Type ty;
      input Boolean b = true;
      input Boolean overwrite = false;
    protected
      list<Integer> sizes;
      Expression start, iter_range, binding = Expression.BOOLEAN(b);
      Option<Expression> step;
      InstNode iter_name;
      list<tuple<InstNode, Expression>> iterators = {};
      Integer index = 1;
    algorithm
      // make array constructor if it is an array
      if Type.isArray(ty) then
        sizes := list(Dimension.size(dim) for dim in Type.arrayDims(ty));
        start         := Expression.INTEGER(1);
        step          := NONE();
        for stop in sizes loop
          iter_name   := InstNode.newIndexedIterator(index);
          iter_range  := Expression.RANGE(Type.INTEGER(), start, step, Expression.INTEGER(stop));
          iterators   := (iter_name, iter_range) :: iterators;
          index       := index + 1;
        end for;
        binding := Expression.CALL(Call.TYPED_ARRAY_CONSTRUCTOR(ty, Expression.variability(binding), NFPrefixes.Purity.PURE, binding, listReverse(iterators)));
      end if;

      attributes := match attributes
        case VAR_ATTR_REAL() guard(overwrite or isNone(attributes.fixed)) algorithm
          attributes.fixed := SOME(binding);
        then attributes;

        case VAR_ATTR_INT() guard(overwrite or isNone(attributes.fixed)) algorithm
          attributes.fixed := SOME(binding);
        then attributes;

        case VAR_ATTR_BOOL() guard(overwrite or isNone(attributes.fixed)) algorithm
          attributes.fixed := SOME(binding);
        then attributes;

        case VAR_ATTR_STRING() guard(overwrite or isNone(attributes.fixed)) algorithm
          attributes.fixed := SOME(binding);
        then attributes;

        case VAR_ATTR_ENUMERATION() guard(overwrite or isNone(attributes.fixed)) algorithm
          attributes.fixed := SOME(binding);
        then attributes;

        else attributes;
      end match;
    end setFixed;

    function isFixed
      input VariableAttributes attributes;
      output Boolean fixed;
    algorithm
      fixed := match attributes
        case VAR_ATTR_REAL(fixed = SOME(Expression.BOOLEAN(value = true)))        then true;
        case VAR_ATTR_INT(fixed = SOME(Expression.BOOLEAN(value = true)))         then true;
        case VAR_ATTR_BOOL(fixed = SOME(Expression.BOOLEAN(value = true)))        then true;
        case VAR_ATTR_STRING(fixed = SOME(Expression.BOOLEAN(value = true)))      then true;
        case VAR_ATTR_ENUMERATION(fixed = SOME(Expression.BOOLEAN(value = true))) then true;
                                                                                  else false;
      end match;
    end isFixed;

    function setStartAttribute
      input output VariableAttributes attributes;
      input Expression start;
      input Boolean overwrite = false;
    algorithm
      attributes := match attributes
        case VAR_ATTR_REAL() guard(overwrite or isNone(attributes.start)) algorithm
          attributes.start := SOME(start);
        then attributes;

        case VAR_ATTR_INT() guard(overwrite or isNone(attributes.start)) algorithm
          attributes.start := SOME(start);
        then attributes;

        case VAR_ATTR_BOOL() guard(overwrite or isNone(attributes.start)) algorithm
          attributes.start := SOME(start);
        then attributes;

        case VAR_ATTR_STRING() guard(overwrite or isNone(attributes.start)) algorithm
          attributes.start := SOME(start);
        then attributes;

        case VAR_ATTR_ENUMERATION() guard(overwrite or isNone(attributes.start)) algorithm
          attributes.start := SOME(start);
        then attributes;

        else attributes;
      end match;
    end setStartAttribute;

    function getStartAttribute
      input VariableAttributes attributes;
      output Option<Expression> start;
    algorithm
      start := match attributes
        case VAR_ATTR_REAL()          then attributes.start;
        case VAR_ATTR_INT()           then attributes.start;
        case VAR_ATTR_BOOL()          then attributes.start;
        case VAR_ATTR_STRING()        then attributes.start;
        case VAR_ATTR_ENUMERATION()   then attributes.start;
        else NONE();
      end match;
    end getStartAttribute;

    function getStateSelect
      input VariableAttributes attributes;
      output StateSelect stateSelect;
    algorithm
      stateSelect := match attributes
        case VAR_ATTR_REAL(stateSelect = SOME(stateSelect)) then stateSelect;
        else StateSelect.DEFAULT;
      end match;
    end getStateSelect;

    function setMin
      input output VariableAttributes attributes;
      input Option<Expression> min_val;
      input Boolean overwrite = false;
    algorithm
      attributes := match attributes

        case VAR_ATTR_REAL() guard(overwrite or isNone(attributes.min)) algorithm
          attributes.min := min_val;
        then attributes;

        case VAR_ATTR_INT() guard(overwrite or isNone(attributes.min)) algorithm
          attributes.min := min_val;
        then attributes;

        case VAR_ATTR_ENUMERATION() guard(overwrite or isNone(attributes.min)) algorithm
          attributes.min := min_val;
        then attributes;

        else attributes;
      end match;
    end setMin;

    function setMax
      input output VariableAttributes attributes;
      input Option<Expression> max_val;
      input Boolean overwrite = false;
    algorithm
      attributes := match attributes

        case VAR_ATTR_REAL() guard(overwrite or isNone(attributes.max))algorithm
          attributes.max := max_val;
        then attributes;

        case VAR_ATTR_INT() guard(overwrite or isNone(attributes.max)) algorithm
          attributes.max := max_val;
        then attributes;

        case VAR_ATTR_ENUMERATION() guard(overwrite or isNone(attributes.max)) algorithm
          attributes.max := max_val;
        then attributes;

        else attributes;
      end match;
    end setMax;

    function setStateSelect
      input output VariableAttributes attributes;
      input StateSelect stateSelect_val;
      input Boolean overwrite = false;
    algorithm
      attributes := match attributes

        case VAR_ATTR_REAL() guard(overwrite or isNone(attributes.stateSelect)) algorithm
          attributes.stateSelect := SOME(stateSelect_val);
        then attributes;

        else attributes;
      end match;
    end setStateSelect;

    function setTearingSelect
      input output VariableAttributes attributes;
      input TearingSelect tearingSelect_val;
      input Boolean overwrite = false;
    algorithm
      attributes := match attributes

        case VAR_ATTR_REAL() guard(overwrite or isNone(attributes.tearingSelect)) algorithm
          attributes.tearingSelect := SOME(tearingSelect_val);
        then attributes;

        else attributes;
      end match;
    end setTearingSelect;

    function getNominal
      input VariableAttributes attr;
      output Option<Expression> nominal;
    algorithm
      nominal := match attr
        case VAR_ATTR_REAL() then attr.nominal;
        else NONE();
      end match;
    end getNominal;

    function scalarizeReal
      input ExpressionIterator        quantity_iter "quantity";
      input ExpressionIterator        unit_iter "SI Unit for actual computation value";
      input ExpressionIterator        displayUnit_iter "SI Unit only for displaying";
      input ExpressionIterator        min_iter "Lower boundry";
      input ExpressionIterator        max_iter "Upper boundry";
      input ExpressionIterator        start_iter "start value";
      input ExpressionIterator        fixed_iter "fixed - true: default for parameter/constant, false - default for other variables";
      input ExpressionIterator        nominal_iter "nominal";
      input Option<StateSelect>       stateSelect "Priority to be selected as a state during index reduction";
      input Option<TearingSelect>     tearingSelect "Priority to be selected as an iteration variable during tearing";
      input Option<Uncertainty>       uncertainty "Attributes from data reconcilliation";
      input Option<Distribution>      distribution "ToDo: ???";
      input ExpressionIterator        binding_iter "A binding expression for certain types. E.G. parameters";
      input Option<Boolean>           isProtected "Defined in protected scope";
      input Option<Boolean>           finalPrefix "Defined as final";
      input ExpressionIterator        startOrigin_iter "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
      input Integer                   length "length of result";
      output list<VariableAttributes> scalar_attributes = {};
    protected
      Option<Expression> quantity, unit, displayUnit, min, max, start, fixed, nominal, binding, startOrigin;
      ExpressionIterator quantity_loc = quantity_iter, unit_loc = unit_iter, displayUnit_loc = displayUnit_iter, min_loc = min_iter, max_loc = max_iter, start_loc = start_iter, fixed_loc = fixed_iter, nominal_loc = nominal_iter, binding_loc = binding_iter, startOrigin_loc = startOrigin_iter;
    algorithm
      for i in 1:length loop
        (quantity_loc, quantity) := ExpressionIterator.nextOpt(quantity_loc);
        (unit_loc, unit) := ExpressionIterator.nextOpt(unit_loc);
        (displayUnit_loc, displayUnit) := ExpressionIterator.nextOpt(displayUnit_loc);
        (min_loc, min) := ExpressionIterator.nextOpt(min_loc);
        (max_loc, max) := ExpressionIterator.nextOpt(max_loc);
        (start_loc, start) := ExpressionIterator.nextOpt(start_loc);
        (fixed_loc, fixed) := ExpressionIterator.nextOpt(fixed_loc);
        (nominal_loc, nominal) := ExpressionIterator.nextOpt(nominal_loc);
        (binding_loc, binding) := ExpressionIterator.nextOpt(binding_loc);
        (startOrigin_loc, startOrigin) := ExpressionIterator.nextOpt(startOrigin_loc);
        scalar_attributes := VAR_ATTR_REAL(quantity,unit,displayUnit,min,max,start,fixed,nominal,stateSelect,tearingSelect,uncertainty,distribution,binding,isProtected,finalPrefix,startOrigin) :: scalar_attributes;
      end for;
      scalar_attributes := listReverse(scalar_attributes);
    end scalarizeReal;

    function scalarizeInt
      input ExpressionIterator        quantity_iter "quantity";
      input ExpressionIterator        min_iter "Lower boundry";
      input ExpressionIterator        max_iter "Upper boundry";
      input ExpressionIterator        start_iter "start value";
      input ExpressionIterator        fixed_iter "fixed - true: default for parameter/constant, false - default for other variables";
      input Option<Uncertainty>       uncertainty "Attributes from data reconcilliation";
      input Option<Distribution>      distribution "ToDo: ???";
      input ExpressionIterator        binding_iter "A binding expression for certain types. E.G. parameters";
      input Option<Boolean>           isProtected "Defined in protected scope";
      input Option<Boolean>           finalPrefix "Defined as final";
      input ExpressionIterator        startOrigin_iter "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
      input Integer                   length "length of result";
      output list<VariableAttributes> scalar_attributes = {};
    protected
      Option<Expression> quantity, min, max, start, fixed, binding, startOrigin;
      ExpressionIterator quantity_loc = quantity_iter, min_loc = min_iter, max_loc = max_iter, start_loc = start_iter, fixed_loc = fixed_iter, binding_loc = binding_iter, startOrigin_loc = startOrigin_iter;
    algorithm
      for i in 1:length loop
        (quantity_loc, quantity) := ExpressionIterator.nextOpt(quantity_loc);
        (min_loc, min) := ExpressionIterator.nextOpt(min_loc);
        (max_loc, max) := ExpressionIterator.nextOpt(max_loc);
        (start_loc, start) := ExpressionIterator.nextOpt(start_loc);
        (fixed_loc, fixed) := ExpressionIterator.nextOpt(fixed_loc);
        (binding_loc, binding) := ExpressionIterator.nextOpt(binding_loc);
        (startOrigin_loc, startOrigin) := ExpressionIterator.nextOpt(startOrigin_loc);
        scalar_attributes := VAR_ATTR_INT(quantity,min,max,start,fixed,uncertainty,distribution,binding,isProtected,finalPrefix,startOrigin) :: scalar_attributes;
      end for;
      scalar_attributes := listReverse(scalar_attributes);
    end scalarizeInt;

    function scalarizeBool
      input ExpressionIterator        quantity_iter "quantity";
      input ExpressionIterator        start_iter "start value";
      input ExpressionIterator        fixed_iter "fixed - true: default for parameter/constant, false - default for other variables";
      input ExpressionIterator        binding_iter "A binding expression for certain types. E.G. parameters";
      input Option<Boolean>           isProtected "Defined in protected scope";
      input Option<Boolean>           finalPrefix "Defined as final";
      input ExpressionIterator        startOrigin_iter "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
      input Integer                   length "length of result";
      output list<VariableAttributes> scalar_attributes = {};
    protected
      Option<Expression> quantity, start, fixed, binding, startOrigin;
      ExpressionIterator quantity_loc = quantity_iter, start_loc = start_iter, fixed_loc = fixed_iter, binding_loc = binding_iter, startOrigin_loc = startOrigin_iter;
    algorithm
      for i in 1:length loop
        (quantity_loc, quantity) := ExpressionIterator.nextOpt(quantity_loc);
        (start_loc, start) := ExpressionIterator.nextOpt(start_loc);
        (fixed_loc, fixed) := ExpressionIterator.nextOpt(fixed_loc);
        (binding_loc, binding) := ExpressionIterator.nextOpt(binding_loc);
        (startOrigin_loc, startOrigin) := ExpressionIterator.nextOpt(startOrigin_loc);
        scalar_attributes := VAR_ATTR_BOOL(quantity,start,fixed,binding,isProtected,finalPrefix,startOrigin) :: scalar_attributes;
      end for;
      scalar_attributes := listReverse(scalar_attributes);
    end scalarizeBool;

    function scalarizeClock
      input Option<Boolean>               isProtected "Defined in protected scope";
      input Option<Boolean>               finalPrefix "Defined as final";
      input Integer                       length "length of result";
      output list<VariableAttributes>     scalar_attributes = List.fill(VAR_ATTR_CLOCK(isProtected, finalPrefix), length);
    end scalarizeClock;

    function scalarizeString
      input ExpressionIterator        quantity_iter "quantity";
      input ExpressionIterator        start_iter "start value";
      input ExpressionIterator        fixed_iter "fixed - true: default for parameter/constant, false - default for other variables";
      input ExpressionIterator        binding_iter "A binding expression for certain types. E.G. parameters";
      input Option<Boolean>           isProtected "Defined in protected scope";
      input Option<Boolean>           finalPrefix "Defined as final";
      input ExpressionIterator        startOrigin_iter "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
      input Integer                   length "length of result";
      output list<VariableAttributes> scalar_attributes = {};
    protected
     Option<Expression> quantity, start, fixed, binding, startOrigin;
      ExpressionIterator quantity_loc = quantity_iter, start_loc = start_iter, fixed_loc = fixed_iter, binding_loc = binding_iter, startOrigin_loc = startOrigin_iter;
    algorithm
      for i in 1:length loop
        (quantity_loc, quantity) := ExpressionIterator.nextOpt(quantity_loc);
        (start_loc, start) := ExpressionIterator.nextOpt(start_loc);
        (fixed_loc, fixed) := ExpressionIterator.nextOpt(fixed_loc);
        (binding_loc, binding) := ExpressionIterator.nextOpt(binding_loc);
        (startOrigin_loc, startOrigin) := ExpressionIterator.nextOpt(startOrigin_loc);
        scalar_attributes := VAR_ATTR_STRING(quantity,start,fixed,binding,isProtected,finalPrefix,startOrigin) :: scalar_attributes;
      end for;
      scalar_attributes := listReverse(scalar_attributes);
    end scalarizeString;

    function scalarizeEnumeration
      input ExpressionIterator        quantity_iter "quantity";
      input ExpressionIterator        min_iter "Lower boundry";
      input ExpressionIterator        max_iter "Upper boundry";
      input ExpressionIterator        start_iter "start value";
      input ExpressionIterator        fixed_iter "fixed - true: default for parameter/constant, false - default for other variables";
      input ExpressionIterator        binding_iter "A binding expression for certain types. E.G. parameters";
      input Option<Boolean>           isProtected "Defined in protected scope";
      input Option<Boolean>           finalPrefix "Defined as final";
      input ExpressionIterator        startOrigin_iter "where did start=X came from? NONE()|SOME(Expression.STRING binding|type|undefined)";
      input Integer                   length "length of result";
      output list<VariableAttributes> scalar_attributes = {};
    protected
      Option<Expression> quantity, min, max, start, fixed, binding, startOrigin;
      ExpressionIterator quantity_loc = quantity_iter, min_loc = min_iter, max_loc = max_iter, start_loc = start_iter, fixed_loc = fixed_iter, binding_loc = binding_iter, startOrigin_loc = startOrigin_iter;
    algorithm
      for i in 1:length loop
        (quantity_loc, quantity) := ExpressionIterator.nextOpt(quantity_loc);
        (min_loc, min) := ExpressionIterator.nextOpt(min_loc);
        (max_loc, max) := ExpressionIterator.nextOpt(max_loc);
        (start_loc, start) := ExpressionIterator.nextOpt(start_loc);
        (fixed_loc, fixed) := ExpressionIterator.nextOpt(fixed_loc);
        (binding_loc, binding) := ExpressionIterator.nextOpt(binding_loc);
        (startOrigin_loc, startOrigin) := ExpressionIterator.nextOpt(startOrigin_loc);
        scalar_attributes :=  VAR_ATTR_ENUMERATION(quantity,min,max,start,fixed,binding,isProtected,finalPrefix,startOrigin) :: scalar_attributes;
      end for;
      scalar_attributes := listReverse(scalar_attributes);
    end scalarizeEnumeration;

    function scalarize
      input VariableAttributes attributes;
      input Integer length;
      output list<VariableAttributes> scalar_attributes = {};
    algorithm
      scalar_attributes := match attributes
        case VAR_ATTR_REAL() then scalarizeReal(
          quantity_iter       = ExpressionIterator.fromExpOpt(attributes.quantity),
          unit_iter           = ExpressionIterator.fromExpOpt(attributes.unit),
          displayUnit_iter    = ExpressionIterator.fromExpOpt(attributes.displayUnit),
          min_iter            = ExpressionIterator.fromExpOpt(attributes.min),
          max_iter            = ExpressionIterator.fromExpOpt(attributes.max),
          start_iter          = ExpressionIterator.fromExpOpt(attributes.start),
          fixed_iter          = ExpressionIterator.fromExpOpt(attributes.fixed),
          nominal_iter        = ExpressionIterator.fromExpOpt(attributes.nominal),
          stateSelect         = attributes.stateSelect,
          tearingSelect       = attributes.tearingSelect,
          uncertainty         = attributes.uncertainty,
          distribution        = attributes.distribution,
          binding_iter        = ExpressionIterator.fromExpOpt(attributes.binding),
          isProtected         = attributes.isProtected,
          finalPrefix         = attributes.finalPrefix,
          startOrigin_iter    = ExpressionIterator.fromExpOpt(attributes.startOrigin),
          length              = length
        );

        case VAR_ATTR_INT() then scalarizeInt(
          quantity_iter       = ExpressionIterator.fromExpOpt(attributes.quantity),
          min_iter            = ExpressionIterator.fromExpOpt(attributes.min),
          max_iter            = ExpressionIterator.fromExpOpt(attributes.max),
          start_iter          = ExpressionIterator.fromExpOpt(attributes.start),
          fixed_iter          = ExpressionIterator.fromExpOpt(attributes.fixed),
          uncertainty         = attributes.uncertainty,
          distribution        = attributes.distribution,
          binding_iter        = ExpressionIterator.fromExpOpt(attributes.binding),
          isProtected         = attributes.isProtected,
          finalPrefix         = attributes.finalPrefix,
          startOrigin_iter    = ExpressionIterator.fromExpOpt(attributes.startOrigin),
          length              = length
        );

        case VAR_ATTR_BOOL() then scalarizeBool(
          quantity_iter       = ExpressionIterator.fromExpOpt(attributes.quantity),
          start_iter          = ExpressionIterator.fromExpOpt(attributes.start),
          fixed_iter          = ExpressionIterator.fromExpOpt(attributes.fixed),
          binding_iter        = ExpressionIterator.fromExpOpt(attributes.binding),
          isProtected         = attributes.isProtected,
          finalPrefix         = attributes.finalPrefix,
          startOrigin_iter    = ExpressionIterator.fromExpOpt(attributes.startOrigin),
          length              = length
        );

        case VAR_ATTR_CLOCK() then scalarizeClock(
          isProtected         = attributes.isProtected,
          finalPrefix         = attributes.finalPrefix,
          length              = length
        );

        case VAR_ATTR_STRING() then scalarizeString(
          quantity_iter       = ExpressionIterator.fromExpOpt(attributes.quantity),
          start_iter          = ExpressionIterator.fromExpOpt(attributes.start),
          fixed_iter          = ExpressionIterator.fromExpOpt(attributes.fixed),
          binding_iter        = ExpressionIterator.fromExpOpt(attributes.binding),
          isProtected         = attributes.isProtected,
          finalPrefix         = attributes.finalPrefix,
          startOrigin_iter    = ExpressionIterator.fromExpOpt(attributes.startOrigin),
          length              = length
        );

        case VAR_ATTR_ENUMERATION() then scalarizeEnumeration(
          quantity_iter       = ExpressionIterator.fromExpOpt(attributes.quantity),
          min_iter            = ExpressionIterator.fromExpOpt(attributes.min),
          max_iter            = ExpressionIterator.fromExpOpt(attributes.max),
          start_iter          = ExpressionIterator.fromExpOpt(attributes.start),
          fixed_iter          = ExpressionIterator.fromExpOpt(attributes.fixed),
          binding_iter        = ExpressionIterator.fromExpOpt(attributes.binding),
          isProtected         = attributes.isProtected,
          finalPrefix         = attributes.finalPrefix,
          startOrigin_iter    = ExpressionIterator.fromExpOpt(attributes.startOrigin),
          length              = length
        );

        // kabdelhak: ToDo: need to discuss this case
        case VAR_ATTR_RECORD() then {attributes};

        else algorithm
          Error.assertion(false, getInstanceName() + "failed. Not yet handled: " + toString(attributes), sourceInfo());
        then fail();
      end match;
    end scalarize;

    function elemType
      input VariableAttributes attr;
      output Type ty;
    algorithm
      ty := match attr
        case VAR_ATTR_REAL()    then Type.REAL();
        case VAR_ATTR_INT()     then Type.INTEGER();
        case VAR_ATTR_BOOL()    then Type.BOOLEAN();
        case VAR_ATTR_CLOCK()   then Type.CLOCK();
        case VAR_ATTR_STRING()  then Type.STRING();
        // should probably add enumeration but currently the needed info is not stored here
        else algorithm
          Error.assertion(false, getInstanceName() + " cannot create type from attributes: " + toString(attr), sourceInfo());
        then fail();
      end match;
    end elemType;

  //protected
    function attributesToString
      input list<tuple<String, Option<Expression>>> tpl_list;
      input Option<StateSelect> stateSelect;
      input Option<TearingSelect> tearingSelect;
      output String str = "";
    protected
      list<String> buffer = {};
      String name;
    algorithm
      for tpl in tpl_list loop
        buffer := attributeToString(tpl, buffer);
      end for;

      buffer := stateSelectStringBuffer(stateSelect, buffer);
      buffer := tearingSelectStringBuffer(tearingSelect, buffer);

      buffer := listReverse(buffer);

      if not listEmpty(buffer) then
        name :: buffer := buffer;
        str := str + name;
        for name in buffer loop
          str := str + ", " + name;
        end for;
      end if;
    end attributesToString;

    function attributeToString
      "Creates an optional string for an optional attribute."
      input tuple<String, Option<Expression>> tpl;
      input output list<String> buffer;
    protected
      String name;
      Option<Expression> optAttr;
      Expression attr;
    algorithm
      (name, optAttr) := tpl;
      if isSome(optAttr) then
        SOME(attr) := optAttr;
        buffer := name + " = " + Expression.toString(attr) :: buffer;
      end if;
    end attributeToString;

    function stateSelectString
      input StateSelect stateSelect;
      output String str;
    algorithm
      str := match stateSelect
        case StateSelect.NEVER    then "StateSelect = never";
        case StateSelect.AVOID    then "StateSelect = avoid";
        case StateSelect.DEFAULT  then "StateSelect = default";
        case StateSelect.PREFER   then "StateSelect = prefer";
        case StateSelect.ALWAYS   then "StateSelect = always";
      end match;
    end stateSelectString;

    function tearingSelectString
      input TearingSelect tearingSelect;
      output String str;
    algorithm
      str := match tearingSelect
        case TearingSelect.NEVER    then "TearingSelect = never";
        case TearingSelect.AVOID    then "TearingSelect = avoid";
        case TearingSelect.DEFAULT  then "TearingSelect = default";
        case TearingSelect.PREFER   then "TearingSelect = prefer";
        case TearingSelect.ALWAYS   then "TearingSelect = always";
      end match;
    end tearingSelectString;

    function stateSelectStringBuffer
      input Option<StateSelect> optStateSelect;
      input output list<String> buffer;
    protected
      StateSelect stateSelect;
    algorithm
      if isSome(optStateSelect) then
        SOME(stateSelect) := optStateSelect;
        buffer := stateSelectString(stateSelect) :: buffer;
      end if;
    end stateSelectStringBuffer;

    function tearingSelectStringBuffer
      input Option<TearingSelect> optTearingSelect;
      input output list<String> buffer;
    protected
      TearingSelect tearingSelect;
    algorithm
      if isSome(optTearingSelect) then
        SOME(tearingSelect) := optTearingSelect;
        buffer := tearingSelectString(tearingSelect) :: buffer;
      end if;
    end tearingSelectStringBuffer;

  protected
    function createReal
      input list<tuple<String, Binding>> attrs;
      input Boolean isFinal;
      input Option<SCode.Comment> comment;
      output VariableAttributes attributes;
    protected
      String name;
      Binding b;
      Option<Expression> quantity = NONE(), unit = NONE(), displayUnit = NONE();
      Option<Expression> min = NONE(), max = NONE(), start = NONE(), fixed = NONE(), nominal = NONE();
      Option<StateSelect> state_select = NONE();
      Option<TearingSelect> tearing_select = NONE();
    algorithm
      if listEmpty(attrs) and not isFinal then
        attributes := EMPTY_VAR_ATTR_REAL;
      else
        for attr in attrs loop
          (name, b) := attr;
          () := match name
            case "displayUnit"    algorithm displayUnit   := createAttribute(b); then ();
            case "fixed"          algorithm fixed         := createAttribute(b); then ();
            case "max"            algorithm max           := createAttribute(b); then ();
            case "min"            algorithm min           := createAttribute(b); then ();
            case "nominal"        algorithm nominal       := createAttribute(b); then ();
            case "quantity"       algorithm quantity      := createAttribute(b); then ();
            case "start"          algorithm start         := createAttribute(b); then ();
            case "stateSelect"    algorithm state_select  := createStateSelect(b); then ();
            // TODO: VAR_ATTR_REAL has no field for unbounded (which should be named unbound).
            case "unbounded"      then ();
            case "unit"           algorithm unit := createAttribute(b); then ();

            // The attributes should already be type checked, so we shouldn't get any
            // unknown attributes here.
            else
              algorithm
                Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
              then
                fail();
          end match;
        end for;
        tearing_select := createTearingSelect(comment);

        attributes := VariableAttributes.VAR_ATTR_REAL(
          quantity, unit, displayUnit, min, max, start, fixed, nominal,
          state_select, tearing_select, NONE(), NONE(), NONE(), NONE(), SOME(isFinal), NONE());
        end if;
    end createReal;

    function createInt
      input list<tuple<String, Binding>> attrs;
      input Boolean isFinal;
      output VariableAttributes attributes;
    protected
      String name;
      Binding b;
      Option<Expression> quantity = NONE(), min = NONE(), max = NONE();
      Option<Expression> start = NONE(), fixed = NONE();
    algorithm
      if listEmpty(attrs) and not isFinal then
        attributes := EMPTY_VAR_ATTR_INT;
      else
        for attr in attrs loop
          (name, b) := attr;

          () := match name
            case "quantity" algorithm quantity := createAttribute(b); then ();
            case "min"      algorithm min := createAttribute(b); then ();
            case "max"      algorithm max := createAttribute(b); then ();
            case "start"    algorithm start := createAttribute(b); then ();
            case "fixed"    algorithm fixed := createAttribute(b); then ();

            // The attributes should already be type checked, so we shouldn't get any
            // unknown attributes here.
            else
              algorithm
                Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
              then
                fail();
          end match;
        end for;

        attributes := VariableAttributes.VAR_ATTR_INT(
          quantity, min, max, start, fixed,
          NONE(), NONE(), NONE(), NONE(), SOME(isFinal), NONE());
      end if;
    end createInt;

    function createBool
      input list<tuple<String, Binding>> attrs;
      input Boolean isFinal;
      output VariableAttributes attributes;
    protected
      String name;
      Binding b;
      Option<Expression> quantity = NONE(), start = NONE(), fixed = NONE();
    algorithm
      if listEmpty(attrs) and not isFinal then
        attributes := EMPTY_VAR_ATTR_BOOL;
      else
        for attr in attrs loop
          (name, b) := attr;

          () := match name
            case "quantity" algorithm quantity := createAttribute(b); then ();
            case "start"    algorithm start := createAttribute(b); then ();
            case "fixed"    algorithm fixed := createAttribute(b); then ();

            // The attributes should already be type checked, so we shouldn't get any
            // unknown attributes here.
            else
              algorithm
                Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
              then
                fail();
          end match;
        end for;

        attributes := VariableAttributes.VAR_ATTR_BOOL(
          quantity, start, fixed, NONE(), NONE(), SOME(isFinal), NONE());
      end if;
    end createBool;

    function createString
      input list<tuple<String, Binding>> attrs;
      input Boolean isFinal;
      output VariableAttributes attributes;
    protected
      String name;
      Binding b;
      Option<Expression> quantity = NONE(), start = NONE(), fixed = NONE();
    algorithm
      if listEmpty(attrs) and not isFinal then
        attributes := EMPTY_VAR_ATTR_STRING;
      else
        for attr in attrs loop
          (name, b) := attr;

          () := match name
            case "quantity" algorithm quantity := createAttribute(b); then ();
            case "start"    algorithm start := createAttribute(b); then ();
            case "fixed"    algorithm fixed := createAttribute(b); then ();

            // The attributes should already be type checked, so we shouldn't get any
            // unknown attributes here.
            else
              algorithm
                Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
              then
                fail();
          end match;
        end for;

        attributes := VariableAttributes.VAR_ATTR_STRING(
          quantity, start, fixed, NONE(), NONE(), SOME(isFinal), NONE());
      end if;
    end createString;

    function createEnum
      input list<tuple<String, Binding>> attrs;
      input Boolean isFinal;
      output VariableAttributes attributes;
    protected
      String name;
      Binding b;
      Option<Expression> quantity = NONE(), min = NONE(), max = NONE();
      Option<Expression> start = NONE(), fixed = NONE();
    algorithm
      if listEmpty(attrs) and not isFinal then
        attributes := EMPTY_VAR_ATTR_REAL;
      else
        for attr in attrs loop
          (name, b) := attr;

          () := match name
            case "fixed"       algorithm fixed := createAttribute(b); then ();
            case "max"         algorithm max := createAttribute(b); then ();
            case "min"         algorithm min := createAttribute(b); then ();
            case "quantity"    algorithm quantity := createAttribute(b); then ();
            case "start"       algorithm start := createAttribute(b); then ();

            // The attributes should already be type checked, so we shouldn't get any
            // unknown attributes here.
            else
              algorithm
                Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
              then
                fail();
          end match;
        end for;

        attributes := VariableAttributes.VAR_ATTR_ENUMERATION(
          quantity, min, max, start, fixed, NONE(), NONE(), SOME(isFinal), NONE());
      end if;
    end createEnum;

    function createClock
      input Boolean isFinal;
      output VariableAttributes attributes = VAR_ATTR_CLOCK(NONE(), SOME(isFinal));
    end createClock;

    function createRecord
      input list<tuple<String, Binding>> attrs;
      input UnorderedMap<String, Integer> indexMap;
      input list<Variable> children;
      input Boolean isFinal;
      output VariableAttributes attributes;
    protected
      array<VariableAttributes> childrenAttr = arrayCreate(listLength(children), EMPTY_VAR_ATTR_REAL);
      Integer index;
    algorithm
      for var in children loop
        _ := match UnorderedMap.get(ComponentRef.firstName(var.name), indexMap)
          case SOME(index) algorithm
            childrenAttr[index] := create(var.typeAttributes, var.ty, var.attributes, var.children, var.comment);
          then ();
          else ();
        end match;
      end for;
      attributes := VAR_ATTR_RECORD(indexMap, childrenAttr);
    end createRecord;

    function createAttribute
      input Binding binding;
      output Option<Expression> attribute = SOME(Binding.getTypedExp(binding));
    end createAttribute;

    function createStateSelect
      input Binding binding;
      output Option<StateSelect> stateSelect;
    protected
      Expression exp = Binding.getTypedExp(binding);
      String name;
    algorithm
      name := getStateSelectName(exp);
      stateSelect := SOME(lookupStateSelectMember(name));
    end createStateSelect;

    function getStateSelectName
      input Expression exp;
      output String name;
    protected
      Expression arg;
      InstNode node;
      Call call;
      list<Expression> rest;
    algorithm
      name := match exp
        case Expression.ENUM_LITERAL() then exp.name;
        case Expression.CREF(cref = ComponentRef.CREF(node = node)) then InstNode.name(node);
        case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()) then getStateSelectName(call.exp);
        case Expression.CALL(call = call as Call.TYPED_CALL(arguments = arg::_))
          guard(AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn)) == "fill")
        then getStateSelectName(arg);
        case Expression.ARRAY() algorithm
          arg :: rest := arrayList(exp.elements);
          if not (listEmpty(rest) or List.all(rest, function Expression.isEqual(exp2=arg))) then
            Error.assertion(false, getInstanceName() +
              " cannot handle array StateSelect with different values yet:" + Expression.toString(exp), sourceInfo());
            fail();
          end if;
        then getStateSelectName(arg);
        else algorithm
          Error.assertion(false, getInstanceName() +
            " got invalid StateSelect expression " + Expression.toString(exp), sourceInfo());
        then fail();
      end match;
    end getStateSelectName;

    function lookupStateSelectMember
      input String name;
      output StateSelect stateSelect;
    algorithm
      stateSelect := match name
        case "never"    then StateSelect.NEVER;
        case "avoid"    then StateSelect.AVOID;
        case "default"  then StateSelect.DEFAULT;
        case "prefer"   then StateSelect.PREFER;
        case "always"   then StateSelect.ALWAYS;
        else
          algorithm
            Error.assertion(false, getInstanceName() + " got unknown StateSelect literal " + name, sourceInfo());
          then
            fail();
      end match;
    end lookupStateSelectMember;

    function createTearingSelect
      "__OpenModelica_tearingSelect is an annotation and has to be extracted from the comment."
      input Option<SCode.Comment> optComment;
      output Option<TearingSelect> tearingSelect = NONE();
    protected
      Option<SCode.Annotation> opt_anno;
      SCode.Annotation anno;
      SCode.Mod mod;
      Option<Absyn.Exp> opt_val;
      Absyn.Exp val;
      String name;
      SourceInfo info;
    algorithm
      opt_anno := SCodeUtil.optCommentAnnotation(optComment);

      if isNone(opt_anno) then
        // No annotation.
        return;
      end if;

      SOME(anno) := opt_anno;
      mod := SCodeUtil.lookupAnnotation(anno, "__OpenModelica_tearingSelect");

      if SCodeUtil.isEmptyMod(mod) then
        mod := SCodeUtil.lookupAnnotation(anno, "tearingSelect");

        if not SCodeUtil.isEmptyMod(mod) then
          Error.addSourceMessage(Error.DEPRECATED_EXPRESSION,
            {"tearingSelect", "__OpenModelica_tearingSelect"}, SCodeUtil.getModifierInfo(mod));
        end if;
      end if;

      opt_val := SCodeUtil.getModifierBinding(mod);

      if isNone(opt_val) then
        // Annotation exists but has no value.
        return;
      end if;

      SOME(val) := opt_val;
      info := SCodeUtil.getModifierInfo(mod);
      name := getTearingSelectName(val, info);
      tearingSelect := lookupTearingSelectMember(name);

      if isNone(tearingSelect) then
        Error.addSourceMessage(Error.UNKNOWN_ANNOTATION_VALUE, {Dump.printExpStr(val)}, info);
      end if;
    end createTearingSelect;

    function getTearingSelectName
      input Absyn.Exp exp;
      input SourceInfo info;
      output String name;
    algorithm
      name := match exp
        // TearingSelect.name
        case Absyn.Exp.CREF(componentRef =
               Absyn.ComponentRef.CREF_QUAL(name = "TearingSelect", subscripts = {}, componentRef =
                 Absyn.ComponentRef.CREF_IDENT(name = name, subscripts = {})))
          then name;

        // Single name without the TearingSelect prefix is deprecated but still accepted.
        case Absyn.Exp.CREF(componentRef = Absyn.ComponentRef.CREF_IDENT(name = name, subscripts = {}))
          algorithm
            Error.addSourceMessage(Error.DEPRECATED_EXPRESSION, {name, "TearingSelect." + name}, info);
          then
            name;

        else "";
      end match;
    end getTearingSelectName;

    function lookupTearingSelectMember
      input String name;
      output Option<TearingSelect> tearingSelect;
    algorithm
      tearingSelect := match name
        case "never"    then SOME(TearingSelect.NEVER);
        case "avoid"    then SOME(TearingSelect.AVOID);
        case "default"  then SOME(TearingSelect.DEFAULT);
        case "prefer"   then SOME(TearingSelect.PREFER);
        case "always"   then SOME(TearingSelect.ALWAYS);
        else NONE();
      end match;
    end lookupTearingSelectMember;
  end VariableAttributes;

  constant VariableAttributes EMPTY_VAR_ATTR_REAL         = VAR_ATTR_REAL(NONE(),NONE(),NONE(), NONE(), NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
  constant VariableAttributes EMPTY_VAR_ATTR_INT          = VAR_ATTR_INT(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
  constant VariableAttributes EMPTY_VAR_ATTR_BOOL         = VAR_ATTR_BOOL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
  constant VariableAttributes EMPTY_VAR_ATTR_CLOCK        = VAR_ATTR_CLOCK(NONE(),NONE());
  constant VariableAttributes EMPTY_VAR_ATTR_STRING       = VAR_ATTR_STRING(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
  constant VariableAttributes EMPTY_VAR_ATTR_ENUMERATION  = VAR_ATTR_ENUMERATION(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());

  type StateSelect = enumeration(NEVER, AVOID, DEFAULT, PREFER, ALWAYS);
  type TearingSelect = enumeration(NEVER, AVOID, DEFAULT, PREFER, ALWAYS);
  type Uncertainty = enumeration(GIVEN, SOUGHT, REFINE, PROPAGATE);

  uniontype Distribution
    record DISTRIBUTION
      Expression name;
      Expression params;
      Expression paramNames;
    end DISTRIBUTION;
  end Distribution;

  uniontype Annotations
    record ANNOTATIONS
      "all annotations that are vendor specific
      note: doesn't include __OpenModelica_tearingSelect, this is considered a first class attribute"
      Boolean hideResult;
      Boolean resizable;
    end ANNOTATIONS;

    function create
      input Option<SCode.Comment> comment;
      input Attributes attributes;
      output Annotations annotations = EMPTY_ANNOTATIONS;
    protected
      SCode.Mod mod;
      Boolean b;
    algorithm
      // set if it was set globally
      if attributes.isResizable then
        annotations.resizable := true;
      end if;

      _ := match comment
        case SOME(SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(modification=mod as SCode.MOD())))) algorithm
          for submod in mod.subModLst loop
            _ := match submod
              case SCode.NAMEMOD(ident = "HideResult", mod = SCode.MOD(binding = SOME(Absyn.BOOL(true)))) algorithm
                annotations.hideResult := true;
              then ();
              case SCode.NAMEMOD(ident = "__OpenModelica_resizable", mod = SCode.MOD(binding = SOME(Absyn.BOOL(b)))) algorithm
                annotations.resizable := b;
              then ();
              else ();
            end match;
          end for;
        then ();
        else ();
      end match;
    end create;
  end Annotations;

  constant Annotations EMPTY_ANNOTATIONS = ANNOTATIONS(false, false);

  annotation(__OpenModelica_Interface="frontend");
end NFBackendExtension;
