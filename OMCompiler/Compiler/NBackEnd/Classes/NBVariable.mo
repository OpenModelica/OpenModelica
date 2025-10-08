/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBVariable
" file:         NBVariable.mo
  description:  This ONLY contains the backend variable functions!
  ===================================================================
  kabdelhak: The Variable declarations for this file are defined in
  NFVariable.mo to avoid that the FrontEnd depends on the BackEnd
  due to the component references containing an InstNode with a
  pointer to a variable.
  ===================================================================
"

public
  //OF Imports
  import SCodeUtil;

  //NF Imports
  import Attributes = NFAttributes;
  import BackendExtension = NFBackendExtension;
  import NFBackendExtension.{BackendInfo, StateSelect, VariableAttributes, VariableKind};
  import NFBinding.Binding;
  import Ceval = NFCeval;
  import Class = NFClass;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Scalarize = NFScalarize;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend Imports
  import NBAdjacency.Mapping;
  import BackendDAE = NBackendDAE;
  import BackendUtil = NBBackendUtil;
  import BEquation = NBEquation;
  import NBEquation.Iterator;
  import BVariable = NBVariable;

  //Util Imports
  import Array;
  import BaseHashTable;
  import ExpandableArray;
  import Slice = NBSlice;
  import StringUtil;
  import UnorderedMap;
  import Util;

public
  type VariablePointer = Pointer<Variable> "mainly used for mapping purposes";

  // ==========================================================================
  //               Single Variable constants and functions
  // ==========================================================================
  constant Variable DUMMY_VARIABLE = Variable.VARIABLE(ComponentRef.EMPTY(), Type.ANY(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFAttributes.DEFAULT_ATTR,
    {}, {}, SCode.noComment, SCodeUtil.dummyInfo, NFBackendExtension.DUMMY_BACKEND_INFO);

  constant Variable SUBST_VARIABLE = Variable.VARIABLE(NFBuiltin.SUBST_CREF, Type.ANY(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFAttributes.DEFAULT_ATTR,
    {}, {}, SCode.noComment, SCodeUtil.dummyInfo, NFBackendExtension.DUMMY_BACKEND_INFO);

  constant Variable TIME_VARIABLE = Variable.VARIABLE(NFBuiltin.TIME_CREF, Type.REAL(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFAttributes.DEFAULT_ATTR,
    {}, {}, SCode.noComment, SCodeUtil.dummyInfo, BackendInfo.BACKEND_INFO(
    VariableKind.TIME(), NFBackendExtension.EMPTY_VAR_ATTR_REAL, NFBackendExtension.EMPTY_ANNOTATIONS, NONE(), NONE(), NONE(), NONE()));

  constant String DERIVATIVE_STR          = "$DER";
  constant String DUMMY_DERIVATIVE_STR    = "$dDER";
  constant String PARTIAL_DERIVATIVE_STR  = "$pDER";
  constant String FUNCTION_DERIVATIVE_STR = "$fDER";
  constant String FUNCTION_STR            = "$FUN";
  constant String PREVIOUS_STR            = "$PRE";
  constant String AUXILIARY_STR           = "$AUX";
  constant String START_STR               = "$START";
  constant String RESIDUAL_STR            = "$RES";
  constant String TEMPORARY_STR           = "$TMP";
  constant String SEED_STR                = "$SEED";
  constant String TIME_EVENT_STR          = "$TEV";
  constant String STATE_EVENT_STR         = "$SEV";
  constant String CLOCK_STR               = "$CLK";

  function toString
    input Variable var;
    input output String str = "";
  protected
    String attr;
  algorithm
    attr := VariableAttributes.toString(var.backendinfo.attributes);
    str := str + VariableKind.toString(var.backendinfo.varKind) + " (" + intString(Variable.size(var, true)) + ") " + Variable.toString(var) + (if attr == "" then "" else " " + attr);
  end toString;

  function pointerToString
    input Pointer<Variable> var_ptr;
    output String str = toString(Pointer.access(var_ptr));
  end pointerToString;

  function nameString
    input Pointer<Variable> var_ptr;
    output String str = ComponentRef.toString(getVarName(var_ptr));
  end nameString;

  function hash
    input Pointer<Variable> var_ptr;
    output Integer i = Variable.hash(Pointer.access(var_ptr));
  end hash;

  function equalName
    input Pointer<Variable> var_ptr1;
    input Pointer<Variable> var_ptr2;
    output Boolean b = Variable.equalName(Pointer.access(var_ptr1), Pointer.access(var_ptr2));
  end equalName;

  function size
    input Pointer<Variable> var_ptr;
    input Boolean resize = false;
    output Integer s = Variable.size(Pointer.access(var_ptr), resize);
  end size;

  function applyToType
    input Pointer<Variable> var_ptr;
    input typeFunc func;
    partial function typeFunc
      input output Type ty;
    end typeFunc;
  protected
    Variable new, var = Pointer.access(var_ptr);
  algorithm
    new := Variable.applyToType(var, func);
    if not referenceEq(var, new) then
      Pointer.update(var_ptr, new);
    end if;
  end applyToType;

  function fromCref
    input ComponentRef cref;
    input Attributes attr = NFAttributes.DEFAULT_ATTR;
    input Binding binding = NFBinding.EMPTY_BINDING;
    output Variable variable;
  protected
    InstNode node, class_node;
    array<InstNode> child_nodes;
    ComponentRef child_cref;
    Type ty;
    Prefixes.Visibility vis;
    SourceInfo info;
    Integer complexSize;
    list<Variable> children = {};
  algorithm
    node := ComponentRef.node(cref);
    ty   := ComponentRef.getSubscriptedType(cref, true);
    vis  := InstNode.visibility(node);
    info := InstNode.info(node);
    // get the record children if the variable is a record (and not an external object)
    if not Type.isExternalObject(ty) then
      children := match Type.arrayElementType(ty)
        case Type.COMPLEX(cls = class_node) algorithm
          child_nodes := Class.getComponents(InstNode.getClass(class_node));
          children := list(fromCref(ComponentRef.prefixCref(c, InstNode.getType(c), {}, cref)) for c in child_nodes);
        then children;
        else {};
      end match;
    end if;

    variable := Variable.VARIABLE(cref, ty, binding, vis, attr, {}, children, SCode.noComment, info, NFBackendExtension.DUMMY_BACKEND_INFO);
  end fromCref;

  function makeVarPtrCyclic
    "Needs a prepared variable and name cref and creates a cyclic dependency between
    a pointer to the variable and its component reference."
    input Variable var;
    output Pointer<Variable> var_ptr;
    input output ComponentRef name;
  algorithm
    var_ptr := Pointer.create(var);
    name := BackendDAE.lowerComponentReferenceInstNode(name, var_ptr);
    var.name := name;
    Pointer.update(var_ptr, var);
  end makeVarPtrCyclic;

  function connectPartners
    "sets the partner for the variable and also sets the variable pointer at the partner variable"
    input Pointer<Variable> var_ptr;
    input Pointer<Variable> par_ptr;
    input BackendInfo.setPartner func;
  protected
    Variable var = Pointer.access(var_ptr);
    Variable par = Pointer.access(par_ptr);
  algorithm
    var.backendinfo := func(var.backendinfo, SOME(par_ptr));
    par.backendinfo := func(par.backendinfo, SOME(var_ptr));
    Pointer.update(var_ptr, var);
    Pointer.update(par_ptr, par);
  end connectPartners;

  function removePartner
    "removes the partner for the variable"
    input Pointer<Variable> var_ptr;
    input BackendInfo.setPartner func;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    var.backendinfo := func(var.backendinfo, NONE());
    Pointer.update(var_ptr, var);
  end removePartner;

  function getVar
    input ComponentRef cref;
    input SourceInfo info;
    output Variable var;
  algorithm
    var := Pointer.access(getVarPointer(cref, info));
  end getVar;

  // The following functions provide layers of protection. Whenever accessing names or pointers use these!
  function getVarPointer
    input ComponentRef cref;
    input SourceInfo info;
    output Pointer<Variable> var;
  algorithm
    var := match cref
      local
        Pointer<Variable> varPointer;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = varPointer)) then varPointer;
      case ComponentRef.CREF(node = InstNode.NAME_NODE())                       then Pointer.create(DUMMY_VARIABLE);
      case ComponentRef.WILD()                                                  then Pointer.create(DUMMY_VARIABLE);
      else algorithm
        Error.addInternalError(getInstanceName() + " failed for " + ComponentRef.toString(cref) +
          ", because of wrong InstNode (not VAR_NODE). Show lowering errors with -d=failtrace.", info);
      then fail();
    end match;
  end getVarPointer;

  function getVarName
    input Pointer<Variable> var_ptr;
    output ComponentRef name;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    name := var.name;
  end getVarName;

  function setVarName
    input output Pointer<Variable> var_ptr;
    input ComponentRef name;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    var.name := name;
    Pointer.update(var_ptr, var);
  end setVarName;

  function subIdxName
    "creates new variable pointer to not change the old variable!"
    input output Pointer<Variable> var_ptr;
    input Pointer<Integer> index;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    var.name := ComponentRef.rename(ComponentRef.firstName(var.name) + "_" + intString(Pointer.access(index)), var.name);
    var_ptr := Pointer.create(var);
  end subIdxName;

  function getVarKind
    input Pointer<Variable> var_ptr;
    output VariableKind kind;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    kind := BackendInfo.getVarKind(var.backendinfo);
  end getVarKind;

  function toExpression
    input Pointer<Variable> var_ptr;
    output Expression exp = Expression.fromCref(getVarName(var_ptr));
  end toExpression;

  partial function checkVar
    input Pointer<Variable> var_ptr;
    output Boolean b;
  protected
    Variable var = Pointer.access(var_ptr);
  end checkVar;

  function isArray
    extends checkVar;
  algorithm
    b := Type.isArray(var.ty);
  end isArray;

  function getDimensions
    input Pointer<Variable> var_ptr;
    output List<Dimension> dims;
  protected
    Variable var;
  algorithm
    var := Pointer.access(var_ptr);
    dims := Type.arrayDims(var.ty);
  end getDimensions;

  function isEmpty
    extends checkVar;
  algorithm
    b := ComponentRef.isEmpty(var.name);
  end isEmpty;

  function isState
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.STATE() then true;
      else false;
    end match;
  end isState;

  function isStateDerivative
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.STATE_DER() then true;
      else false;
    end match;
  end isStateDerivative;

  function isAlgebraic
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.ALGEBRAIC() then true;
      else false;
    end match;
  end isAlgebraic;

  function isStart
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.START() then true;
      else false;
    end match;
  end isStart;

  function isExtObj
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.EXTOBJ() then true;
      else false;
    end match;
  end isExtObj;

  function isTime
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.TIME() then true;
      else false;
    end match;
  end isTime;

  function isContinuous
    extends checkVar;
    input Boolean init  "true if it's an initial system";
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.DISCRETE_STATE()  then false; // like parameter?
      case VariableKind.DISCRETE()        then false; // like parameter?
      case VariableKind.PREVIOUS()        then false; // like parameter?
      case VariableKind.CONSTANT()        then false;
      case VariableKind.ITERATOR()        then false;
      case VariableKind.EXTOBJ()          then false;
      case VariableKind.PARAMETER()       then init and Type.isContinuous(var.ty);
      else true;
    end match;
  end isContinuous;

  function isDiscreteState
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.DISCRETE_STATE() then true;
      else false;
    end match;
  end isDiscreteState;

  function isDiscrete
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.DISCRETE() then true;
      else false;
    end match;
  end isDiscrete;

  function isPrevious
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.PREVIOUS() then true;
      else false;
    end match;
  end isPrevious;

  function isRecord
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.RECORD() then true;
      else false;
    end match;
  end isRecord;

  function isKnownRecord
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      local
        Prefixes.Variability variability;
      case VariableKind.RECORD(max_var = variability) guard(variability < NFPrefixes.Variability.DISCRETE) then true;
      else false;
    end match;
  end isKnownRecord;

 function isUnknownRecord
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      local
        Prefixes.Variability variability;
      case VariableKind.RECORD(min_var = variability) guard(variability > NFPrefixes.Variability.NON_STRUCTURAL_PARAMETER) then true;
      else false;
    end match;
  end isUnknownRecord;

  function isClock
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.CLOCK() then true;
      else false;
    end match;
  end isClock;

  function isClocked
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.CLOCKED() then true;
      else false;
    end match;
  end isClocked;

  function isIterator
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.ITERATOR() then true;
      else false;
    end match;
  end isIterator;

  partial function getVarPartner
    input Pointer<Variable> var_ptr;
    output Option<Pointer<Variable>> partner;
    output String partnerName "for error messages";
  protected
    Variable var = Pointer.access(var_ptr);
  end getVarPartner;

  function getVarPre
    "Gets the pre() / previous() var if its a variable / clocked variable or the other way around."
    extends getVarPartner;
  algorithm
    partnerName := "pre variable";
    partner := var.backendinfo.var_pre;
  end getVarPre;

  function getVarSeed
    "Gets the SEED var to the variable or the other way around."
    extends getVarPartner;
  algorithm
    partnerName := "seed variable";
    partner := var.backendinfo.var_seed;
  end getVarSeed;

  function getVarPDer
    "Gets the partial derivative of a residual or the other way around."
    extends getVarPartner;
  algorithm
    partnerName := "partial derivative";
    partner := var.backendinfo.var_pder;
  end getVarPDer;

  function getVarDer
    "Returns the derivative from a state.
    Only works after the state has been detected by the DetectStates module."
    extends getVarPartner;
  algorithm
    partnerName := "derivative";
    partner := match var.backendinfo.varKind
      case VariableKind.STATE(derivative = partner) then partner;
      else NONE();
    end match;
  end getVarDer;

  function getVarState
    extends getVarPartner;
  algorithm
    partnerName := "state";
    partner := match var.backendinfo.varKind
      local
        Pointer<Variable> p;
      case VariableKind.STATE_DER(state = p) then SOME(p);
      else NONE();
    end match;
  end getVarState;

  function getVarDummyDer
    "Returns the dummy derivative from a dummy state.
    Only works after the dummy state has been created by the IndexReduction module"
    extends getVarPartner;
  algorithm
    partnerName := "dummy derivative";
    partner := match var.backendinfo.varKind
      local
        Pointer<Variable> p;
      case VariableKind.DUMMY_STATE(dummy_der = p) then SOME(p);
      else NONE();
    end match;
  end getVarDummyDer;

  function getPartnerCref
    "Like getVarPartner but for cref. Fails if there is no partner."
    input ComponentRef cref;
    input getVarPartner func;
    input Boolean scalarized = false;
    output ComponentRef partner_cref;
  protected
    Option<Pointer<Variable>> partner;
    String partnerName;
  algorithm
    (partner, partnerName) := func(getVarPointer(cref, sourceInfo()));
    if isSome(partner) then
      partner_cref := getVarName(Util.getOption(partner));
      if not scalarized then
        partner_cref := ComponentRef.copySubscripts(cref, partner_cref);
      end if;
    else
      Error.addMessage(Error.INTERNAL_ERROR,
        {getInstanceName() + " failed because " + ComponentRef.toString(cref)
         + " has no corresponding " + partnerName + "."});
      fail();
    end if;
  end getPartnerCref;

  function hasStartAttr
    extends checkVar;
  algorithm
    b := Util.isSome(VariableAttributes.getStartAttribute(var.backendinfo.attributes));
  end hasStartAttr;

  function hasPre
    "only returns true if the variable itself is not a pre() or previous() and has a pre() pointer set"
    extends checkVar;
  algorithm
    b := not isPrevious(var_ptr) and Util.isSome(getVarPre(var_ptr));
  end hasPre;

  function isDummyState
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.DUMMY_STATE() then true;
      else false;
    end match;
  end isDummyState;

  function isDummyDer
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.DUMMY_DER() then true;
      else false;
    end match;
  end isDummyDer;

  function isParamOrConst
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.PARAMETER() then true;
      case VariableKind.CONSTANT()  then true;
      else false;
    end match;
  end isParamOrConst;

  function isConst
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.CONSTANT() then true;
      else false;
    end match;
  end isConst;

  function isKnown
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.PARAMETER() then true;
      case VariableKind.CONSTANT()  then true;
      case VariableKind.STATE()     then true;
      else false;
    end match;
  end isKnown;

  function isResizable
    extends checkVar;
  algorithm
    b := List.any(Type.arrayDims(var.ty), Dimension.isResizable);
  end isResizable;

  function isResizableParameter
    extends checkVar;
  algorithm
    b := match var.backendinfo
      case BackendExtension.BACKEND_INFO(varKind = VariableKind.PARAMETER(), annotations = BackendExtension.ANNOTATIONS(resizable = true))
      then true;
      else false;
    end match;
  end isResizableParameter;

  function updateResizableParameter
    input Pointer<Variable> var_ptr;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
  protected
    Variable var = Pointer.access(var_ptr);
    Option<Expression> val = UnorderedMap.get(var.name, optimal_values);
  algorithm
    _ := match (val, var.backendinfo)
      local
        Integer i;
        VariableKind varKind;

      case (SOME(Expression.INTEGER(i)), BackendExtension.BACKEND_INFO(varKind = varKind as VariableKind.PARAMETER(), annotations = BackendExtension.ANNOTATIONS(resizable = true))) algorithm
        varKind.resize_value := SOME(i);
        setVarKind(var_ptr, varKind);
      then ();
      else ();
    end match;
  end updateResizableParameter;

  function getResizableValue
    input Pointer<Variable> var_ptr;
    output Integer val;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    _ := match var.backendinfo
      case BackendExtension.BACKEND_INFO(varKind = VariableKind.PARAMETER(resize_value = SOME(val))) then val;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because following variable is not a resizable parameter: " + toString(var)});
      then fail();
    end match;
  end getResizableValue;

  function isResidual
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.RESIDUAL_VAR() then true;
      else false;
    end match;
  end isResidual;

  function isSeed
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.SEED_VAR() then true;
      else false;
    end match;
  end isSeed;

  function isInput
    extends checkVar;
  algorithm
    b := var.attributes.direction == NFPrefixes.Direction.INPUT;
  end isInput;

  function isOutput
    extends checkVar;
  algorithm
    b := var.attributes.direction == NFPrefixes.Direction.OUTPUT;
  end isOutput;

  function isFixed
    extends checkVar;
  algorithm
    // FIXME use VariableAttributes.isFixed()?
    b := match var.backendinfo.attributes
      local
        Expression fixed;
      case VariableAttributes.VAR_ATTR_REAL(fixed = SOME(fixed))        then Expression.isAllTrue(fixed);
      case VariableAttributes.VAR_ATTR_INT(fixed = SOME(fixed))         then Expression.isAllTrue(fixed);
      case VariableAttributes.VAR_ATTR_BOOL(fixed = SOME(fixed))        then Expression.isAllTrue(fixed);
      case VariableAttributes.VAR_ATTR_STRING(fixed = SOME(fixed))      then Expression.isAllTrue(fixed);
      case VariableAttributes.VAR_ATTR_ENUMERATION(fixed = SOME(fixed)) then Expression.isAllTrue(fixed);
      else false;
    end match;
  end isFixed;

  function isFixable
    "states, discretes and parameters are fixable if they are not already fixed.
    discrete states are always fixable. previous vars are only fixable if the discrete state for it wasn't fixed."
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.STATE()          then not isFixed(var_ptr);
      case VariableKind.DISCRETE_STATE() then not isFixed(var_ptr) or hasPre(var_ptr);
      case VariableKind.PARAMETER()      then not isFixed(var_ptr);
      case VariableKind.PREVIOUS()       then true;
      else false;
    end match;
  end isFixable;

  function isStateSelect
    "checks if a variable has a certain StateSelect attribute"
    extends checkVar;
    input StateSelect stateSelect;
  algorithm
    b := VariableAttributes.getStateSelect(var.backendinfo.attributes) == stateSelect;
  end isStateSelect;

  function setVariableAttributes
    input output Variable var;
    input VariableAttributes variableAttributes;
  algorithm
    var := match var
      local
        BackendInfo backendinfo;
      case NFVariable.VARIABLE(backendinfo = backendinfo) algorithm
        backendinfo.attributes := variableAttributes;
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setVariableAttributes;

  function setMin
    input output Variable var;
    input Option<Expression> min_val;
    input Boolean overwrite = false;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo backendinfo;
        BackendExtension.VariableAttributes variableAttributes;
      case NFVariable.VARIABLE(backendinfo = backendinfo as BackendExtension.BACKEND_INFO(attributes = variableAttributes)) algorithm

        backendinfo.attributes := BackendExtension.VariableAttributes.setMin(variableAttributes, min_val, overwrite);
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setMin;

  function setMax
    input output Variable var;
    input Option<Expression> max_val;
    input Boolean overwrite = false;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo backendinfo;
        BackendExtension.VariableAttributes variableAttributes;
      case NFVariable.VARIABLE(backendinfo = backendinfo as BackendExtension.BACKEND_INFO(attributes = variableAttributes)) algorithm

        backendinfo.attributes := BackendExtension.VariableAttributes.setMax(variableAttributes, max_val, overwrite);
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setMax;

  function setStartAttribute
    input output Variable var;
    input Expression start_val;
    input Boolean overwrite = false;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo backendinfo;
        BackendExtension.VariableAttributes variableAttributes;
      case NFVariable.VARIABLE(backendinfo = backendinfo as BackendExtension.BACKEND_INFO(attributes = variableAttributes)) algorithm

        backendinfo.attributes := BackendExtension.VariableAttributes.setStartAttribute(variableAttributes, start_val, overwrite);
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setStartAttribute;

  function setStateSelect
    input output Variable var;
    input BackendExtension.StateSelect stateSelect_val;
    input Boolean overwrite = false;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo backendinfo;
        BackendExtension.VariableAttributes variableAttributes;
      case NFVariable.VARIABLE(backendinfo = backendinfo as BackendExtension.BACKEND_INFO(attributes = variableAttributes)) algorithm

        backendinfo.attributes := BackendExtension.VariableAttributes.setStateSelect(variableAttributes, stateSelect_val, overwrite);
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setStateSelect;

  function setTearingSelect
    input output Variable var;
    input BackendExtension.TearingSelect tearingSelect_val;
    input Boolean overwrite = false;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo backendinfo;
        BackendExtension.VariableAttributes variableAttributes;
      case NFVariable.VARIABLE(backendinfo = backendinfo as BackendExtension.BACKEND_INFO(attributes = variableAttributes)) algorithm

        backendinfo.attributes := BackendExtension.VariableAttributes.setTearingSelect(variableAttributes, tearingSelect_val, overwrite);
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setTearingSelect;

  function setVarKind
    "use with caution: some variable kinds have extra information that needs to be correct"
    input Pointer<Variable> varPointer;
    input VariableKind varKind;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := BackendInfo.setVarKind(var.backendinfo, varKind);
    Pointer.update(varPointer, var);
  end setVarKind;

  function setParent
    "sets the record parent. only do for record elements!"
    input output Pointer<Variable> varPointer;
    input Pointer<Variable> parent;
  protected
    Variable var = Pointer.access(varPointer);
  algorithm
    var.backendinfo := BackendInfo.setParent(var.backendinfo, parent);
    Pointer.update(varPointer, var);
  end setParent;

  function getParent
    "returns the optional record parent"
    input Pointer<Variable> varPointer;
    output Option<Pointer<Variable>> parent;
  protected
    Variable var = Pointer.access(varPointer);
  algorithm
    parent := var.backendinfo.parent;
  end getParent;

  function isDummyVariable
    "Returns true, if the variable is a dummy variable.
    Note: !Only works in the backend, will return true for any variable if used
    during frontend!"
    extends checkVar;
  algorithm
    b := match var.backendinfo.varKind
      case VariableKind.FRONTEND_DUMMY() then true;
      else false;
    end match;
  end isDummyVariable;

  function isArtificial
    extends checkVar;
  algorithm
    b := StringUtil.startsWith(ComponentRef.firstName(getVarName(var_ptr)), "$");
  end isArtificial;

  function isFunctionAlias
    extends checkVar;
  algorithm
    b := StringUtil.startsWith(ComponentRef.firstName(getVarName(var_ptr)), FUNCTION_STR);
  end isFunctionAlias;

  function isClockAlias
    extends checkVar;
  algorithm
    b := StringUtil.startsWith(ComponentRef.firstName(getVarName(var_ptr)), CLOCK_STR);
  end isClockAlias;

  function createTimeVar
    output Pointer<Variable> var_ptr;
  protected
    Variable var = TIME_VARIABLE;
  algorithm
    (var_ptr, _) := makeVarPtrCyclic(var, var.name);
  end createTimeVar;

  function setStateDerivativeVar
    "Updates a variable pointer to be a state, requires the pointer to its derivative."
    input Pointer<Variable> varPointer;
    input Pointer<Variable> derivative;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.STATE(1, SOME(derivative), true));
    Pointer.update(varPointer, var);
  end setStateDerivativeVar;

  function makeAlgStateVar
    "Updates a variable pointer to be an algebraic state.
    Only if it currently is an algebraic variable, required for DAEMode."
    input Pointer<Variable> varPointer;
  protected
    Variable var;
  algorithm
    if isAlgebraic(varPointer) then
      var := Pointer.access(varPointer);
      var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.ALG_STATE());
      Pointer.update(varPointer, var);
    end if;
  end makeAlgStateVar;

  function makeDerVar
    "Creates a derivative variable pointer from the state cref.
    e.g. height -> $DER.height"
    input ComponentRef cref           "old component reference";
    input Boolean scalarized = false;
    output ComponentRef der_cref      "new component reference";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  protected
    ComponentRef state_cref = if scalarized then cref else ComponentRef.stripSubscriptsAll(cref);
  algorithm
    () := match ComponentRef.node(state_cref)
      local
        InstNode derNode;
        Pointer<Variable> state, dummy_ptr = Pointer.create(DUMMY_VARIABLE);
        Variable var;
      case InstNode.VAR_NODE()
        algorithm
          state := getVarPointer(state_cref, sourceInfo());
          // append the $DER to the name
          derNode := InstNode.VAR_NODE(DERIVATIVE_STR, dummy_ptr);
          der_cref := ComponentRef.append(state_cref, ComponentRef.fromNode(derNode, ComponentRef.scalarType(state_cref)));
          // make the actual derivative variable and make cref and the variable cyclic
          var := fromCref(ComponentRef.stripSubscriptsAll(der_cref), Variable.attributes(Pointer.access(state)));
          var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.STATE_DER(state, NONE()));
          (var_ptr, der_cref) := makeVarPtrCyclic(var, der_cref);
          if not scalarized then
            der_cref := ComponentRef.copySubscripts(cref, der_cref);
          end if;
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeDerVar;

  function hasDerVar
    input Pointer<Variable> state_var;
    output Boolean b;
  algorithm
    b := match Pointer.access(state_var)
      case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(varKind = VariableKind.STATE(derivative = SOME(_)))) then true;
      else false;
    end match;
  end hasDerVar;

  function addRecordChild
    "adds a child to the records children. use with care, only when creating new records!"
    input Pointer<Variable> var_ptr;
    input Pointer<Variable> child;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    var := match var
      local
        VariableKind varKind;
      case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(varKind = varKind as VariableKind.RECORD())) algorithm
        varKind.children := child :: varKind.children;
        var.backendinfo := BackendInfo.setVarKind(var.backendinfo, varKind);
      then var;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed adding " + ComponentRef.toString(getVarName(child)) + " as a child to "
          + ComponentRef.toString(getVarName(var_ptr)) + " because it is not a record."});
      then fail();
    end match;
    Pointer.update(var_ptr, var);
  end addRecordChild;

  function setRecordChildren
    "sets the records children. use with care, only when creating new records!"
    input Pointer<Variable> var_ptr;
    input list<Pointer<Variable>> children;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    var := match var
      local
        VariableKind varKind;
      case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(varKind = varKind as VariableKind.RECORD())) algorithm
        varKind.children := children;
        var.backendinfo := BackendInfo.setVarKind(var.backendinfo, varKind);
      then var;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed adding new children to "
          + ComponentRef.toString(getVarName(var_ptr)) + " because it is not a record."});
      then fail();
    end match;
    Pointer.update(var_ptr, var);
  end setRecordChildren;

  function getRecordChildren
    "returns all children of the variable if its a record, otherwise returns empty list"
    input Pointer<Variable> var;
    output list<Pointer<Variable>> children;
  algorithm
    children := match Pointer.access(var)
      local
        VariableKind varKind;
      case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(varKind = varKind as VariableKind.RECORD()))
      then varKind.children;
      else {};
    end match;
  end getRecordChildren;

  function getRecordChildrenCref
    input ComponentRef cref;
    output list<ComponentRef> children;
  protected
    list<Subscript> subscripts;
    list<Pointer<Variable>> arg_children;
  algorithm
    subscripts    := ComponentRef.subscriptsAllFlat(cref);
    arg_children  := BVariable.getRecordChildren(getVarPointer(cref, sourceInfo()));
    children      := list(ComponentRef.mergeSubscripts(subscripts, getVarName(child), true, true) for child in arg_children);
  end getRecordChildrenCref;

  function getRecordChildrenCrefOrSelf
    input ComponentRef cref;
    output list<ComponentRef> children = getRecordChildrenCref(cref);
  algorithm
    children := if listEmpty(children) then {cref} else children;
  end getRecordChildrenCrefOrSelf;

  function makeDummyState
    input Pointer<Variable> varPointer;
    output Pointer<Variable> derivative;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := match BackendInfo.getVarKind(var.backendinfo)
      local
        VariableKind varKind;
        Variable der_var;

      case varKind as VariableKind.STATE(derivative = SOME(derivative)) algorithm
        // also update the derivative to be a dummy derivative
        der_var := Pointer.access(derivative);
        der_var.backendinfo := BackendInfo.setVarKind(der_var.backendinfo, VariableKind.DUMMY_DER(varPointer));
        Pointer.update(derivative, der_var);
      then BackendInfo.setVarKind(var.backendinfo, VariableKind.DUMMY_STATE(derivative));

      // do nothing if its already a dummy state
      case VariableKind.DUMMY_STATE(dummy_der = derivative) then var.backendinfo;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(getVarName(varPointer)) + "."});
      then fail();
    end match;
    Pointer.update(varPointer, var);
  end makeDummyState;

  function makeDiscreteStateVar
    "Updates a discrete variable pointer to be a discrete state, requires the pointer to its left limit (pre) variable."
    input Pointer<Variable> varPointer;
  protected
    Variable var = Pointer.access(varPointer);
  algorithm
    var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.DISCRETE_STATE());
    Pointer.update(varPointer, var);
  end makeDiscreteStateVar;

  function makePreVar
    "Creates a previous variable pointer from the variable cref.
    e.g. isOpen -> $PRE.isOpen"
    input ComponentRef cref           "old component reference";
    output ComponentRef pre_cref      "new component reference";
    output Pointer<Variable> pre_ptr  "pointer to new variable";
  algorithm
    () := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> var_ptr;
        Variable pre;
      case qual as InstNode.VAR_NODE()
        algorithm
          var_ptr := BVariable.getVarPointer(cref, sourceInfo());
          qual.name := PREVIOUS_STR;
          pre_cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          pre := fromCref(pre_cref, Variable.attributes(Pointer.access(var_ptr)));
          pre.backendinfo := BackendInfo.setVarKind(pre.backendinfo, VariableKind.PREVIOUS());
          (pre_ptr, pre_cref) := makeVarPtrCyclic(pre, pre_cref);
          connectPartners(var_ptr, pre_ptr, BackendInfo.setVarPre);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makePreVar;

  function makeSeedVar
    "Creates a seed variable pointer from a cref. Used in NBJacobian and NBHessian
    to represent generic gradient equations.
    e.g: (speed, 'Jac') -> $SEED_Jac.speed"
    input output ComponentRef cref    "old component reference to new component reference";
    input String name                 "name of the matrix this seed belongs to";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    () := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> old_var_ptr;
        Option<Pointer<Variable>> ovar;
        Variable var;
        VariableKind varKind;

      case qual as InstNode.VAR_NODE() algorithm
        // get the variable pointer from the old cref to later on link back to it
        old_var_ptr := getVarPointer(cref, sourceInfo());
        ovar := getVarSeed(old_var_ptr);
        if isSome(ovar) then
          var_ptr := Util.getOption(ovar);
          cref := getVarName(var_ptr);
        else
          // prepend the seed str and the matrix name and create the new cref
          qual.name := SEED_STR + "_" + name;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(cref, NFAttributes.IMPL_DISCRETE_ATTR);

          // update the variable to be a seed and pass the pointer to the original variable
          // if it is a record, clear the children instead
          varKind := match getVarKind(old_var_ptr)
            case varKind as VariableKind.RECORD() algorithm
              varKind.children := {};
            then varKind;
            else VariableKind.SEED_VAR();
          end match;
          var.backendinfo := BackendInfo.setVarKind(var.backendinfo, varKind);

          // create the new variable pointer and safe it to the component reference
          (var_ptr, cref) := makeVarPtrCyclic(var, cref);
          connectPartners(old_var_ptr, var_ptr, BackendInfo.setVarSeed);
        end if;
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeSeedVar;

  function makePDerVar
    "Creates a partial derivative variable pointer from a cref. Used in NBJacobian and NBHessian
    to represent generic gradient equations.
    e.g: (speed, 'Jac') -> $pDer_Jac.speed"
    input output ComponentRef cref    "old component reference to new component reference";
    input String name                 "name of the matrix this partial derivative belongs to";
    input Boolean isTmp               "sets variable kind for tmpVar or resultVar accordingly";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    () := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> res_ptr;
        Option<Pointer<Variable>> ovar;
        VariableKind varKind;
        Variable var;

      // regular case for jacobians
      case qual as InstNode.VAR_NODE() algorithm
        res_ptr := getVarPointer(cref, sourceInfo());
        ovar := getVarPDer(res_ptr);
        if isSome(ovar) then
          var_ptr := Util.getOption(ovar);
          cref := getVarName(var_ptr);
        else
          // prepend the seed str and the matrix name and create the new cref_DIFF_DIFF
          qual.name := PARTIAL_DERIVATIVE_STR + "_" + name;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(cref, Variable.attributes(Pointer.access(res_ptr)));

          // update the variable to be a partial derivative and pass the pointer to the original variable
          // if it is a record, clear the children instead
          varKind := match getVarKind(res_ptr)
            case varKind as VariableKind.RECORD() algorithm
              varKind.children := {};
            then varKind;
            else if isTmp then VariableKind.JAC_TMP_VAR() else VariableKind.JAC_VAR();
          end match;
          var.backendinfo := BackendInfo.setVarKind(var.backendinfo, varKind);


          // create the new variable pointer and safe it to the component reference
          (var_ptr, cref) := makeVarPtrCyclic(var, cref);
          connectPartners(res_ptr, var_ptr, BackendInfo.setVarPDer);
        end if;
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makePDerVar;

  function makeFDerVar
    "Creates a function derivative cref. Used in NBDifferentiation
    for differentiating body vars of a function (crefs are not lowered and only known locally).
    prepend the funcion derivative name and use the string representation of the cref
    for interface reasons they have to be a single cref without restCref (gets converted to InstNode)"
    input output ComponentRef cref    "old component reference to new component reference";
  algorithm
    cref := match ComponentRef.node(cref)
      local
        InstNode qual;

      // inside a function body
      case qual as InstNode.COMPONENT_NODE() algorithm
        qual.name := BackendUtil.makeFDerString(ComponentRef.toString(cref));
        cref := ComponentRef.fromNode(qual, ComponentRef.nodeType(cref));
      then cref;

      // partial function application (passing function pointers)
      case qual as InstNode.CLASS_NODE() algorithm
        qual.name := BackendUtil.makeFDerString(ComponentRef.toString(cref));
        cref := ComponentRef.fromNode(qual, ComponentRef.nodeType(cref));
      then cref;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeFDerVar;

  function makeStartVar
    "Creates a start variable pointer from a cref. Used in NBInitialization.
    e.g: angle -> $START.angle"
    input ComponentRef cref           "old component reference";
    output ComponentRef start_cref    "new component reference";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    () := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> old_var_ptr;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          // get the variable pointer from the old cref to later on link back to it
          old_var_ptr := BVariable.getVarPointer(cref, sourceInfo());
          // prepend the start str
          qual.name := START_STR;
          start_cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(start_cref, Variable.attributes(getVar(cref, sourceInfo())));
          // update the variable to be a start variable and pass the pointer to the original variable
          var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.START(old_var_ptr));
          // create the new variable pointer and safe it to the component reference
          (var_ptr, start_cref) := makeVarPtrCyclic(var, start_cref);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeStartVar;

  function makeResidualVar
    "Creates a residual variable pointer from a unique index and context name.
    e.g. (\"DAE\", 4) --> $RES_DAE_4"
    input String name                 "context name e.g. DAE";
    input Integer uniqueIndex         "unique identifier index";
    input Type ty                     "equation type containing dims";
    output Pointer<Variable> var_ptr  "pointer to new variable";
    output ComponentRef cref          "new component reference";
  protected
    InstNode node;
    Variable var;
    list<Dimension> dims = Type.arrayDims(ty);
  algorithm
    // create inst node with dummy variable pointer and create cref from it
    node := InstNode.VAR_NODE(RESIDUAL_STR + "_" + name + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    // Type for residuals is always REAL() !
    cref := ComponentRef.CREF(node, {}, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    // create variable and set its kind to dae_residual (change name?)
    var := fromCref(cref);
    // update the variable to be a seed and pass the pointer to the original variable
    var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.RESIDUAL_VAR());
    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
  end makeResidualVar;

  function makeEventVar
    "Creates a generic boolean variable pointer from a unique index and context name.
    e.g. (\"$SEV\", 4) --> $SEV_4"
    input String name                           "context name e.g. §WHEN";
    input Integer uniqueIndex                   "unique identifier index";
    input Type var_ty                           "variable type";
    input Iterator iterator = Iterator.EMPTY()  "optional for-loop iterator";
    output Pointer<Variable> var_ptr            "pointer to new variable";
    output ComponentRef cref                    "new component reference";
  protected
    InstNode node;
    ComponentRef var_cref;
    Variable var;
    list<ComponentRef> iter_crefs;
    list<Subscript> iter_subs;
    list<Integer> sub_sizes;
    Type ty;
  algorithm
    // get subscripts from optional iterator
    (iter_crefs, _) := Iterator.getFrames(iterator);
    iter_subs := list(Subscript.fromTypedExp(Expression.fromCref(iter)) for iter in iter_crefs);
    if listEmpty(iter_subs) then
      ty := var_ty;
    else
      sub_sizes := Iterator.sizes(iterator);
      ty := Type.liftArrayLeftList(var_ty, list(Dimension.fromInteger(sub_size) for sub_size in sub_sizes));
    end if;
    // create inst node with dummy variable pointer and create cref from it
    node := InstNode.VAR_NODE(name + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    cref := ComponentRef.CREF(node, iter_subs, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    var_cref := ComponentRef.CREF(node, {}, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    // create variable
    var := fromCref(var_cref, NFAttributes.IMPL_DISCRETE_ATTR);
    // update the variable to be discrete and pass the pointer to the original variable
    var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.DISCRETE());
    var.backendinfo := BackendInfo.setHideResult(var.backendinfo, true);
    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
  end makeEventVar;

  function makeAuxVar
    "Creates an auxillary variable pointer from a unique index and context name.
    e.g. (\"FUN\", 4) --> $FUN_4"
    input String name                 "context name e.g. FUN";
    input Integer uniqueIndex         "unique identifier index";
    input Type ty                     "variable type containing dims";
    input Boolean makeParam           "true if it is a parameter";
    output Pointer<Variable> var_ptr  "pointer to new variable";
    output ComponentRef cref          "new component reference";
  protected
    InstNode node;
    Variable var;
    list<Dimension> dims = Type.arrayDims(ty);
    function updateBackendInfo
      input output Variable var;
      input Boolean makeParam;
    algorithm
      // update the variable kind and set hideResult = true
      var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.fromType(Variable.typeOf(var), makeParam));
      var.backendinfo := BackendInfo.setHideResult(var.backendinfo, true);
    end updateBackendInfo;
  algorithm
    // create inst node with dummy variable pointer and create cref from it
    node  := InstNode.VAR_NODE(name + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    cref  := ComponentRef.CREF(node, {}, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    var   := fromCref(cref);

    var := updateBackendInfo(var, makeParam);
    var.children := list(updateBackendInfo(child, makeParam) for child in var.children);

    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
  end makeAuxVar;

  function makeAuxStateVar
    "Creates a auxiliary state variable from an expression.
    e.g. der(x^2 + y) --> der(aux)"
    input Integer uniqueIndex         "unique identifier index";
    input Option<Expression> binding  "optional binding expression";
    output Pointer<Variable> var_ptr  "pointer to new variable";
    output ComponentRef cref          "new component reference";
    output Pointer<Variable> der_var  "pointer to new derivative variable";
    output ComponentRef der_cref      "new derivative component reference";
  protected
    InstNode node;
    Variable var;
    Expression bnd;
  algorithm
    // create inst node with dummy variable pointer and create cref from it
    node := InstNode.VAR_NODE(AUXILIARY_STR + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    cref := ComponentRef.CREF(node, {}, Type.REAL(), NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    // create variable and add optional binding
    if isSome(binding) then
      bnd := Util.getOption(binding);
      var := fromCref(cref, NFAttributes.DEFAULT_ATTR, Binding.FLAT_BINDING(bnd, Expression.variability(bnd), NFBinding.Source.BINDING));
    else
      var := fromCref(cref);
    end if;
    // update the variable to be a seed and pass the pointer to the original variable
    var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.ALGEBRAIC());
    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
    (der_cref, der_var) := makeDerVar(cref);
    setStateDerivativeVar(var_ptr, der_var);
  end makeAuxStateVar;

  function makeTmpVar
    "Creates a tmp variable pointer from a cref. Used in NBInitialization.
    e.g: angle -> $START.angle"
    input ComponentRef cref           "old component reference";
    output ComponentRef tmp_cref    "new component reference";
  protected
    Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    () := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> old_var_ptr;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          // get the variable pointer from the old cref to later on link back to it
          old_var_ptr := BVariable.getVarPointer(cref, sourceInfo());
          // prepend the tmp str
          qual.name := TEMPORARY_STR;
          tmp_cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(tmp_cref, Variable.attributes(getVar(cref, sourceInfo())));
          // update the variable to be a start variable and pass the pointer to the original variable
          var.backendinfo := BackendInfo.setVarKind(var.backendinfo, getVarKind(old_var_ptr));
          // create the new variable pointer and safe it to the component reference
          (var_ptr, tmp_cref) := makeVarPtrCyclic(var, tmp_cref);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeTmpVar;

  function makeClockVar
    "Creates a clock variable if an unnamed clock is used in the system"
    input Integer uniqueIndex         "unique identifier index";
    input Type ty                     "equation type containing dims";
    output Pointer<Variable> var_ptr  "pointer to new variable";
    output ComponentRef cref          "new component reference";
  protected
    InstNode node;
    Variable var;
    list<Dimension> dims = Type.arrayDims(ty);
  algorithm
    // create inst node with dummy variable pointer and create cref from it
    node := InstNode.VAR_NODE(CLOCK_STR + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    // Type for residuals is always REAL() !
    cref := ComponentRef.CREF(node, {}, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    // create variable and set its kind to dae_residual (change name?)
    var := fromCref(cref);
    // update the variable to be a seed and pass the pointer to the original variable
    var.backendinfo := BackendInfo.setVarKind(var.backendinfo, VariableKind.CLOCK());
    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
  end makeClockVar;

  function getBindingVariability
    "returns the variability of the binding, fails if it has the wrong type.
    unbound variables return the most restrictive variability because they have
    to be solved by the system."
    input Pointer<Variable> var_ptr;
    output Prefixes.Variability variability;
  algorithm
    variability := match Pointer.access(var_ptr)
      local
        Prefixes.Variability tmp;
      case Variable.VARIABLE(binding = Binding.TYPED_BINDING(variability = tmp))    then tmp;
      case Variable.VARIABLE(binding = Binding.FLAT_BINDING(variability = tmp))     then tmp;
      case Variable.VARIABLE(binding = Binding.UNBOUND())                           then NFPrefixes.Variability.CONTINUOUS;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding."});
      then fail();
    end match;
  end getBindingVariability;

  function hasEvaluableBinding
    extends checkVar;
  protected
    Expression binding;
  algorithm
    if isBound(var_ptr) then
      binding := Binding.getExp(var.binding);
      b := Expression.isLiteral(binding);
      if not b then
        // try to extract literal from array constructor (use dummy map, there should not be any new iterators)
        (_, binding) := Iterator.extract(binding);
        binding := SimplifyExp.simplifyDump(binding, true, getInstanceName());
        b := Expression.isLiteral(Ceval.tryEvalExp(binding));
      end if;
    else
      b := false;
    end if;
  end hasEvaluableBinding;

  function mapExp
    input Pointer<Variable> var_ptr;
    input BEquation.MapFuncExp funcExp;
    input BEquation.MapFuncExpWrapper mapFunc = Expression.map;
  protected
    Variable var = Pointer.access(var_ptr);
    Option<Expression> opt_start;
    Expression binding, new_binding, start, new_start;
    Boolean changed = false;
  algorithm
    // map binding
    if isBound(var_ptr) then
      binding     := Binding.getExp(var.binding);
      new_binding := mapFunc(binding, funcExp);
      if not referenceEq(binding, new_binding) then
        var.binding := Binding.setExp(new_binding, var.binding);
        changed     := true;
      end if;
    end if;

    // map start exp
    opt_start   := getStartAttribute(var_ptr);
    if Util.isSome(opt_start) then
      SOME(start) := opt_start;
      new_start   := mapFunc(start, funcExp);

      if not referenceEq(start, new_start) then
        var         := setStartAttribute(var, new_start, true);
        changed     := true;
      end if;
    end if;

    if changed then Pointer.update(var_ptr, var); end if;
  end mapExp;

  function setFixed
    input output Pointer<Variable> var_ptr;
    input Boolean b = true;
    input Boolean overwrite = false;
  protected
    Variable var;
  algorithm
    var := Pointer.access(var_ptr);
    var := match var
      local
        BackendInfo binfo;

      case Variable.VARIABLE(backendinfo = binfo as BackendInfo.BACKEND_INFO()) algorithm
        binfo.attributes := VariableAttributes.setFixed(binfo.attributes, var.ty, b, overwrite);
        var.backendinfo := binfo;
      then var;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding."});
      then fail();
    end match;
    Pointer.update(var_ptr, var);
  end setFixed;

  function setBindingAsStart
    "use this if a binding is found out to be constant, remove variable to known vars (param/const)
    NOTE: this overwrites the old start value. throw error/warning if different?"
    input Pointer<Variable> var_ptr;
  protected
    Variable var;
  algorithm
    var := Pointer.access(var_ptr);
    var := match var
      local
        BackendInfo binfo;
        Expression start;

      case Variable.VARIABLE(backendinfo = binfo as BackendInfo.BACKEND_INFO()) algorithm
        start := Binding.getExp(var.binding);
        binfo.attributes := VariableAttributes.setStartAttribute(binfo.attributes, start, true);
        var.backendinfo := binfo;
      then var;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding."});
      then fail();
    end match;
    Pointer.update(var_ptr, var);
  end setBindingAsStart;

  function setBindingAsStartAndFix
    input output Pointer<Variable> var_ptr;
    input Boolean b = true;
  algorithm
    setBindingAsStart(var_ptr);
    var_ptr := setFixed(var_ptr, b);
  end setBindingAsStartAndFix;

  function getStartAttribute
    input Pointer<Variable> var_ptr;
    output Option<Expression> start =  VariableAttributes.getStartAttribute(Variable.getVariableAttributes(Pointer.access(var_ptr)));
  end getStartAttribute;

  function hasNonTrivialAliasBinding
    "returns true if the binding does not represent a cref, a negated cref or a constant.
     used for alias removal since only those can be stored as actual alias variables"
    extends checkVar;
  protected
    Expression binding = Binding.getExp(var.binding);
  algorithm
    b := (not Expression.isTrivialCref(binding)) and checkExpMap(binding, isTimeDependent, sourceInfo());
  end hasNonTrivialAliasBinding;

  function hasConstOrParamAliasBinding
    extends checkVar;
  algorithm
    b := not checkExpMap(Binding.getExp(var.binding), isTimeDependent, sourceInfo());
  end hasConstOrParamAliasBinding;

  function isTimeDependent
    extends checkVar;
  algorithm
    b := VariableKind.isTimeDependent(var.backendinfo.varKind);
  end isTimeDependent;

  function isBound
    extends checkVar;
  algorithm
    b := match var.binding
      case Binding.TYPED_BINDING()    then true;
      case Binding.UNTYPED_BINDING()  then true;
      case Binding.FLAT_BINDING()     then true;
      else false;
    end match;
  end isBound;

  // ==========================================================================
  //                        Other type wrappers
  //
  // ==========================================================================

  function checkExp
    input Expression exp;
    input checkVar func;
    input SourceInfo info;
    output Boolean b;
  algorithm
    b := match exp
      local
        ComponentRef cref;
      case Expression.CREF(cref = cref)
      then func(getVarPointer(cref, info));
      else false;
    end match;
  end checkExp;

  function checkExpMap
    input Expression exp;
    input checkVar func;
    input SourceInfo info;
    output Boolean b;
    function checkExpTraverse
      input output Expression exp;
      input checkVar func;
      input SourceInfo info;
      input output Boolean b;
    algorithm
      if not b then
        b := checkExp(exp, func, info);
      end if;
    end checkExpTraverse;
  algorithm
    (_, b) := Expression.mapFold(exp, function checkExpTraverse(func=func,info=info), false);
  end checkExpMap;

  function checkCref
    input ComponentRef cref;
    input checkVar func;
    input SourceInfo info;
    output Boolean b = func(getVarPointer(cref, info));
  end checkCref;

  // ==========================================================================
  //                        Variable Array Stuff
  //    All variable arrays are pointer arrays to avoid duplicates
  // ==========================================================================
  uniontype VariablePointers
    record VARIABLE_POINTERS
      UnorderedMap<ComponentRef, Integer> map   "Map for cref->index";
      ExpandableArray<Pointer<Variable>> varArr "Array of variable pointers";
      Boolean scalarized                        "true if the variables are scalarized";
    end VARIABLE_POINTERS;

    function toString
      input VariablePointers variables;
      input output String str = "";
      input Option<array<tuple<Integer,Integer>>> mapping_opt = NONE();
      input Boolean printEmpty = true;
    protected
      Integer numberOfElements = VariablePointers.size(variables);
      Integer length, scal_start;
      String index;
      Boolean useMapping = Util.isSome(mapping_opt);
      array<tuple<Integer,Integer>> mapping;
    algorithm
      if useMapping then
        length := 15;
        mapping := Util.getOption(mapping_opt);
      else
        length := 10;
      end if;
      if printEmpty or numberOfElements > 0 then
        str := StringUtil.headline_4(str + " Variables (" + intString(numberOfElements) + "/" + intString(scalarSize(variables, true)) + ")");
        for i in 1:numberOfElements loop
          if useMapping then
            (scal_start, _) := mapping[i];
            index := "(" + intString(i) + "|" + intString(scal_start) + ")";
          else
            index := "(" + intString(i) + ")";
          end if;
          index := index + StringUtil.repeat(" ", length - stringLength(index));
          str := str + BVariable.toString(Pointer.access(ExpandableArray.get(i, variables.varArr)), index) + "\n";
        end for;
        str := str + "\n";
      else
        str := "";
      end if;
    end toString;

    function map
      "Traverses all variables and applies a function to them.
       NOTE: Do not changes names with this, it will mess up the Mapping.
       Introduce new variables and delete old variables for that!"
      input output VariablePointers variables;
      input MapFunc func;
      partial function MapFunc
        input output Variable v;
      end MapFunc;
    protected
      Pointer<Variable> var_ptr;
      Variable var, new_var;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(variables.varArr) loop
        if ExpandableArray.occupied(i, variables.varArr) then
          var_ptr := ExpandableArray.get(i, variables.varArr);
          var := Pointer.access(var_ptr);
          new_var := func(var);
          if not referenceEq(var, new_var) then
            // Do not update the expandable array entry, but the pointer itself
            Pointer.update(var_ptr, new_var);
          end if;
        end if;
      end for;
    end map;

    function mapPtr
      "Traverses all variables as pointers and applies a function to them.
       NOTE: Do not changes names with this, it will mess up the Mapping.
       Introduce new variables and delete old variables for that!
       Also does not check for referenceEq, the function has to update the
       pointer itself!"
      input output VariablePointers variables;
      input MapFunc func;
      partial function MapFunc
        input Pointer<Variable> v;
      end MapFunc;
    protected
      Pointer<Variable> var_ptr;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(variables.varArr) loop
        if ExpandableArray.occupied(i, variables.varArr) then
          var_ptr := ExpandableArray.get(i, variables.varArr);
          func(var_ptr);
        end if;
      end for;
    end mapPtr;

    function mapRemovePtr
      "Traverses all variable pointers and may invoke to remove the variable pointer
      (does not affect other instances of the variable)"
      input output VariablePointers variables;
      input MapFunc func;
      partial function MapFunc
        input Pointer<Variable> v;
        output Boolean delete;
      end MapFunc;
    protected
      Pointer<Variable> var_ptr;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(variables.varArr) loop
        if ExpandableArray.occupied(i, variables.varArr) then
          var_ptr := ExpandableArray.get(i, variables.varArr);
          if func(var_ptr) then
            variables := remove(var_ptr, variables);
          end if;
        end if;
      end for;
      variables := compress(variables);
    end mapRemovePtr;

    function empty
      "Creates an empty VariablePointers using given size * 1.4."
      input Integer size = BaseHashTable.bigBucketSize;
      input Boolean scalarized = false;
      output VariablePointers variables;
    protected
      Integer arr_size, bucketSize;
      UnorderedMap<ComponentRef, Integer> map;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      bucketSize := Util.nextPrime(arr_size);
      if scalarized then
        map := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, bucketSize);
      else
        map := UnorderedMap.new<Integer>(ComponentRef.hashStrip, ComponentRef.isEqualStrip, bucketSize);
      end if;
      variables := VARIABLE_POINTERS(map, ExpandableArray.new(arr_size, Pointer.create(DUMMY_VARIABLE)), scalarized);
    end empty;

    function clone
      input VariablePointers variables;
      input Boolean shallow = true;
      output VariablePointers new;
    algorithm
      if shallow then
        new := fromList(toList(variables));
      else
        new := fromList(list(Pointer.create(Pointer.access(eqn)) for eqn in toList(variables)));
      end if;
    end clone;

    function size
      "returns the number of elements, not the actual scalarized number of variables!"
      input VariablePointers variables;
      output Integer sz = ExpandableArray.getNumberOfElements(variables.varArr);
    end size;

    function scalarSize
      "returns the scalar size."
      input VariablePointers variables;
      input Boolean resize = false;
      output Integer sz = 0;
    algorithm
      for var_ptr in toList(variables) loop
        sz := sz + BVariable.size(var_ptr, resize);
      end for;
    end scalarSize;

    function toList
      "Creates a VariablePointer list from VariablePointers."
      input VariablePointers variables;
      output list<Pointer<Variable>> var_lst;
    algorithm
      var_lst := ExpandableArray.toList(variables.varArr);
    end toList;

    function fromList
      "Creates VariablePointers from a VariablePointer list."
      input list<Pointer<Variable>> var_lst;
      input Boolean scalarized = false;
      output VariablePointers variables;
    algorithm
      variables := empty(listLength(var_lst), scalarized);
      variables := addList(var_lst, variables);
    end fromList;

    function addList
      "Adds a list of variables to the Variables structure. If any variable already
      exists it's updated instead."
      input list<Pointer<Variable>> var_lst;
      input output VariablePointers variables;
    algorithm
      variables := List.fold(var_lst, function add(), variables);
    end addList;

    function removeList
      "Removes a list of variables from the Variables structure."
      input list<Pointer<Variable>> var_lst;
      input output VariablePointers variables;
    algorithm
      variables := List.fold(var_lst, function remove(), variables);
      variables := compress(variables);
    end removeList;

    function add
      "Adds a variable pointer to the set, or updates it if it already exists."
      input Pointer<Variable> varPointer;
      input output VariablePointers variables;
    protected
      Variable var;
      Integer index;
    algorithm
      var := Pointer.access(varPointer);
      () := match UnorderedMap.get(var.name, variables.map)
        case SOME(index) guard(index > 0) algorithm
          ExpandableArray.update(index, varPointer, variables.varArr);
        then ();
        else algorithm
          (_, index) := ExpandableArray.add(varPointer, variables.varArr);
          UnorderedMap.add(var.name, index, variables.map);
        then ();
      end match;
    end add;

    function remove
      "Removes a variable pointer identified by its name from the set."
      input Pointer<Variable> var_ptr;
      input output VariablePointers variables "only an output for mapping";
    protected
      Variable var;
      Integer index;
    algorithm
      var := Pointer.access(var_ptr);
      () := match UnorderedMap.get(var.name, variables.map)
        case SOME(index) guard(index > 0) algorithm
          ExpandableArray.delete(index, variables.varArr);
          // set the index to -1 to avoid removing entries
          UnorderedMap.add(var.name, -1, variables.map);
        then ();
        else ();
      end match;
    end remove;

    function setVarAt
      "Sets a Variable pointer at a specific index in the VariablePointers."
      input VariablePointers variables;
      input Integer idx;
      input Pointer<Variable> var_ptr;
    protected
      Variable var;
    algorithm
      ExpandableArray.set(idx, var_ptr, variables.varArr);
      var := Pointer.access(var_ptr);
      UnorderedMap.add(var.name, idx, variables.map);
    end setVarAt;

    function getVarAt
      "Returns the variable pointer at given index. If there is none it fails."
      input VariablePointers variables;
      input Integer idx;
      output Pointer<Variable> var;
    algorithm
      var := ExpandableArray.get(idx, variables.varArr);
    end getVarAt;

    function getVarSafe
      "Use only for lowering purposes! Otherwise use the InstNode in the
      ComponentRef. Fails if the component ref cannot be found."
      input VariablePointers variables;
      input ComponentRef cref;
      input Option<SourceInfo> info = NONE();
      output Pointer<Variable> var_ptr;
    protected
      Integer index;
    algorithm
      var_ptr := match UnorderedMap.get(cref, variables.map)
        case SOME(index) guard(index > 0) then ExpandableArray.get(index, variables.varArr);
        else algorithm
          if Util.isSome(info) then
            Error.addInternalError(getInstanceName() + " failed for " + ComponentRef.toString(cref), Util.getOption(info));
          end if;
        then fail();
      end match;
    end getVarSafe;

    function getVarIndex
      "Returns -1 if cref was deleted or cannot be found."
      input VariablePointers variables;
      input ComponentRef cref;
      output Integer index = UnorderedMap.getOrDefault(cref, variables.map, -1);
    end getVarIndex;

    function contains
      "Returns true if the variable is in the variable pointer array."
      input Pointer<Variable> var;
      input VariablePointers variables;
      output Boolean b = containsCref(getVarName(var), variables);
    end contains;

    function containsCref
      "Returns true if a variable with this name is in the variable pointer array."
      input ComponentRef cref;
      input VariablePointers variables;
      output Boolean b = getVarIndex(variables, cref) > 0;
    end containsCref;

    function getVarNames
      "returns a list of crefs representing the names of all variables"
      input VariablePointers variables;
      output list<ComponentRef> names;
    protected
      Pointer<list<ComponentRef>> acc = Pointer.create({});
    algorithm
      mapPtr(variables, function getVarNameTraverse(acc = acc));
      names := listReverse(Pointer.access(acc));
    end getVarNames;

    function getScalarVarNames
      "Returns the names of all variables, with arrays and records expanded."
      input VariablePointers variables;
      output list<ComponentRef> names = {};
    protected
      Variable var;
    algorithm
      for var_ptr in toList(variables) loop
        var := Pointer.access(var_ptr);

        if Type.isArray(var.ty) then
          for cr in ComponentRef.scalarizeAll(ComponentRef.stripSubscriptsAll(var.name), true) loop
            if Type.isComplex(ComponentRef.nodeType(cr)) then
              names := listAppend(ComponentRef.getRecordChildren(cr), names);
            else
              names := cr :: names;
            end if;
          end for;
        else
          names := var.name :: names;
        end if;
      end for;
    end getScalarVarNames;

    function getMarkedVars
      input VariablePointers variables;
      input array<Boolean> marks;
      output list<Pointer<Variable>> marked_vars;
    protected
      list<Integer> indices = BackendUtil.findTrueIndices(marks);
    algorithm
      if arrayLength(marks) == VariablePointers.size(variables) then
        marked_vars := list(getVarAt(variables, index) for index in indices);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the number var marks ("
          + intString(arrayLength(marks)) + ") is not equal to the number of variables ("
          + intString(VariablePointers.size(variables)) + ")."});
        fail();
      end if;
    end getMarkedVars;

    function compress "O(n)
      Reorders the elements in order to remove all the gaps.
      Be careful: This changes the indices of the elements.
      Cannot use ExpandableArray.compress since it needs to
      update the UnorderedMap."
      input output VariablePointers variables;
    protected
      list<Pointer<Variable>> vars = {};
    algorithm
      for i in ExpandableArray.getLastUsedIndex(variables.varArr):-1:1 loop
        if ExpandableArray.occupied(i, variables.varArr) then
          vars := ExpandableArray.get(i, variables.varArr) :: vars;
        end if;
      end for;
      variables := fromList(vars);
    end compress;

    function sort
      "author: kabdelhak
      Sorts the variables solely by their attributes and type hash.
      Does not use the name! Used for reproduceable heuristic behavior independent of names."
      input output VariablePointers variables;
    protected
      Integer size;
      list<tuple<Integer, Pointer<Variable>>> hash_lst;
      Pointer<list<tuple<Integer, Pointer<Variable>>>> hash_lst_ptr = Pointer.create({});
      Pointer<Variable> var_ptr;
    algorithm
      // use number of elements
      size := ExpandableArray.getNumberOfElements(variables.varArr);
      // hash all variables and create hash - variable tpl list
      mapPtr(variables, function createSortHashTpl(mod = realInt(size * log(size)), hash_lst_ptr = hash_lst_ptr));
      hash_lst := List.sort(Pointer.access(hash_lst_ptr), BackendUtil.indexTplGt);
      // create new variables and add them one by one in sorted order
      variables := empty(size, variables.scalarized);
      for tpl in hash_lst loop
        (_, var_ptr) := tpl;
        variables := add(var_ptr, variables);
      end for;
    end sort;

    function scalarize
      "author: kabdelhak
      Expands all variables to their scalar elements."
      input output VariablePointers variables;
    protected
      list<Pointer<Variable>> vars;
      Boolean flattened;
    algorithm
      (vars, flattened) := scalarizeList(toList(variables));
      // only change variables if any of them have been flattened
      if flattened then
        variables := fromList(vars, true);
      end if;
    end scalarize;

    function scalarizeList
      input list<Pointer<Variable>> vars;
      output list<Pointer<Variable>> new_vars = {};
      output Boolean flattened = false;
    protected
      list<Variable> scalar_vars, element_vars;
      Variable var;
    algorithm
      for var_ptr in vars loop
        var := Pointer.access(var_ptr);
        // flatten potential arrays
        if Type.isArray(var.ty) then
          flattened := true;
          scalar_vars := Scalarize.scalarizeBackendVariable(var);
        else
          scalar_vars := {Pointer.access(var_ptr)};
        end if;

        // flatten potential records
        for var in scalar_vars loop
          if Type.isComplex(var.ty) then
            flattened := true;
            element_vars := Scalarize.scalarizeComplexVariable(var);
            for elem_var in listReverse(element_vars) loop
              new_vars := Pointer.create(elem_var) :: new_vars;
            end for;
          else
            new_vars := Pointer.create(var) :: new_vars;
          end if;
        end for;
      end for;
      new_vars := listReverse(new_vars);
    end scalarizeList;

    function varSlice
      input VariablePointers vars;
      input Integer scal;
      input Mapping mapping;
      output ComponentRef cref;
    protected
      Pointer<Variable> var;
      Integer arr, start, size;
      Type ty;
      list<Integer> sizes, vals;
    algorithm
      arr := mapping.var_StA[scal];
      (start, size) := mapping.var_AtS[arr];
      var := VariablePointers.getVarAt(vars, arr);
      Variable.VARIABLE(name = cref, ty = ty) := Pointer.access(var);
      sizes := list(Dimension.size(dim) for dim in Type.arrayDims(ty));
      vals := listReverse(Slice.indexToLocation(scal-start, sizes));
      cref := ComponentRef.mergeSubscripts(list(Subscript.INDEX(Expression.INTEGER(val+1)) for val in vals), cref, true, true);
    end varSlice;

  protected
    function createSortHashTpl
      "Helper function for sort(). Creates the hash value without considering the name and
      adds it as a tuple to the list in pointer."
      input Pointer<Variable> var_ptr;
      input Integer mod;
      input Pointer<list<tuple<Integer, Pointer<Variable>>>> hash_lst_ptr;
    protected
      Variable var;
      Integer hash;
    algorithm
      var := Pointer.access(var_ptr);
      // create hash only from backendinfo
      hash := stringHashDjb2Mod(BackendInfo.toString(var.backendinfo), mod);
      Pointer.update(hash_lst_ptr, (hash, var_ptr) :: Pointer.access(hash_lst_ptr));
    end createSortHashTpl;
  end VariablePointers;

  // ==========================================================================
  //                        Variable Data
  //    All variable arrays are pointer arrays to avoid duplicates
  // ==========================================================================
  uniontype VarData
    "All variable arrays are pointer subsets of an array of variables indicated
    by preceding comment. Used to traverse all variables of a special kind."

    record VAR_DATA_SIM
      "Only to be used for simulation systems."
      VariablePointers variables          "All variables";
      /* subset of full variable array */
      VariablePointers unknowns           "All state derivatives, algebraic variables,
                                          discrete variables";
      VariablePointers knowns             "Parameters, constants, states";
      VariablePointers initials           "All initial unknowns (unknowns + states + previous + parameters(non const binding))";
      VariablePointers auxiliaries        "Variables created by the backend known to be solved
                                          by given binding. E.g. $cse";
      VariablePointers aliasVars          "Variables removed due to alias removal with 1 or -1 coefficient";
      VariablePointers nonTrivialAlias    "Variables removed due to alias removal with gain * alias + offset function";

      /* subset of unknowns */
      VariablePointers derivatives        "State derivatives (der(x) -> $DER.x)";
      VariablePointers algebraics         "Algebraic variables";
      VariablePointers discretes          "Discrete variables";
      VariablePointers discrete_states    "Discrete state variables";
      VariablePointers clocked_states     "Clocked state variables";
      VariablePointers previous           "Previous variables (pre(d) -> $PRE.d)";
      VariablePointers clocks             "clock variables";

      /* subset of knowns */
      VariablePointers states             "States";
      VariablePointers top_level_inputs   "Top level inputs";
      VariablePointers resizables         "Resizable Parameters";
      VariablePointers parameters         "Parameters";
      VariablePointers constants          "Constants";
      VariablePointers records            "Records";
      VariablePointers external_objects   "External Objects";
      VariablePointers artificials        "artificial variables to have pointers on crefs";

      /* state order for differentiation and index reduction */
      UnorderedMap<ComponentRef, ComponentRef> state_order;
    end VAR_DATA_SIM;

    record VAR_DATA_JAC
      "Only to be used for Jacobians."
      VariablePointers variables          "All jacobian variables";
      /* subset of full variable array */
      VariablePointers unknowns           "All result and temporary vars"; // FIXME unused?
      VariablePointers knowns             "Parameters, constants";
      VariablePointers auxiliaries        "Variables created by the backend known to be solved
                                          by given binding. E.g. $cse";
      VariablePointers aliasVars          "Variables removed due to alias removal";

      /* subset of global full variable array */
      VariablePointers diffVars           "Differentiation variables z where J = dF/dz";
      VariablePointers dependencies       "All occurring unknowns for linearity analysis";

      /* subset of local unknowns */
      VariablePointers resultVars         "Result variable depending on current seed
                                          ($RES.[jacname].[eq_idx])";
      VariablePointers tmpVars            "Temporary variables (inner partial derivatives)
                                          dy/dz with y!=z for all y and z
                                          ($TMP.[jacname].y)";

      /* subset of auxiliaries */
      VariablePointers seedVars           "Seed variables representing a generic derivative
                                          dx/dz which is 1 for x==z and 0 otherwise.
                                          ($SEED.[jacname].x)";
    end VAR_DATA_JAC;

    record VAR_DATA_HES
      "Only to be used for Hessians."
      VariablePointers variables          "All hessian variables";
      /* subset of full variable array */
      VariablePointers unknowns           "All state derivatives, algebraic variables,
                                          discrete variables";
      VariablePointers knowns             "Parameters, constants";
      VariablePointers auxiliaries        "Variables created by the backend known to be solved
                                          by given binding. E.g. $cse";
      VariablePointers aliasVars          "Variables removed due to alias removal";

      /* subset of global full variable array */
      VariablePointers diffVars           "Differentiation variables z where J = dF/dz";
      VariablePointers dependencies       "All occurring unknowns for linearity analysis";

      /* subset of local unknowns */
      VariablePointers resultVars         "Result variable depending on current seed
                                          ($RES.[jacname].[eq_idx])";
      VariablePointers tmpVars            "Temporary variables (inner partial derivatives)
                                          dy/dz with y!=z for all y and z
                                          ($TMP.[jacname].y)";

      /* subset of auxiliaries */
      VariablePointers seedVars           "Seed variables representing a generic derivative
                                          dx/dz which is 1 for x==z and 0 otherwise.
                                          ($SEED.[jacname].x)";
      /* subset of auxiliaries */
      VariablePointers seedVars2          "Second seed variables representing a generic
                                          derivative dx/dz which is 1 for x==z and 0 otherwise.
                                          ($SEED2.[jacname].x)";
      Option<VariablePointers> lambdaVars "Lambda variables for optimization";
    end VAR_DATA_HES;

    record VAR_DATA_EMPTY end VAR_DATA_EMPTY;

    function size
      input VarData varData;
      output Integer s;
    algorithm
      s := match varData
        case VAR_DATA_SIM() then VariablePointers.size(varData.unknowns);
        case VAR_DATA_JAC() then VariablePointers.size(varData.unknowns);
        case VAR_DATA_HES() then VariablePointers.size(varData.unknowns);
      end match;
    end size;

    function scalarSize
      input VarData varData;
      input Boolean resize = false;
      output Integer s;
    algorithm
      s := match varData
        case VAR_DATA_SIM() then VariablePointers.scalarSize(varData.unknowns, resize);
        case VAR_DATA_JAC() then VariablePointers.scalarSize(varData.unknowns, resize);
        case VAR_DATA_HES() then VariablePointers.scalarSize(varData.unknowns, resize);
      end match;
    end scalarSize;

    function toString
      input VarData varData;
      input Integer level = 0;
      output String str;
    algorithm
      str := if level == 0 then match varData
          case VAR_DATA_SIM()   then VariablePointers.toString(varData.variables, "Simulation");
          case VAR_DATA_JAC()   then VariablePointers.toString(varData.variables, "Jacobian");
          case VAR_DATA_HES()   then VariablePointers.toString(varData.variables, "Hessian");
          case VAR_DATA_EMPTY() then "Empty variable Data!\n";
          else fail();
        end match
      elseif level == 1 then toStringVerbose(varData, false)
      else toStringVerbose(varData, true);
    end toString;

    function toStringVerbose
      input VarData varData;
      input Boolean full = false;
      output String str;
    algorithm
      str := match varData
        local
          String tmp = "";
          VariablePointers lambdaVars;

        case VAR_DATA_SIM() algorithm
          tmp := "Variable Data Simulation (scalar unknowns: " + intString(VariablePointers.scalarSize(varData.unknowns, true)) + ")";
          tmp := StringUtil.headline_2(tmp) + "\n";
          if not full then
            tmp := tmp + VariablePointers.toString(varData.unknowns, "Unknown", NONE(), false) +
              VariablePointers.toString(varData.states, "Local Known", NONE(), false) +
              VariablePointers.toString(varData.knowns, "Global Known", NONE(), false);
          else
            tmp := tmp + VariablePointers.toString(varData.states, "State", NONE(), false) +
              VariablePointers.toString(varData.derivatives, "Derivative", NONE(), false) +
              VariablePointers.toString(varData.algebraics, "Algebraic", NONE(), false) +
              VariablePointers.toString(varData.discretes, "Discrete", NONE(), false) +
              VariablePointers.toString(varData.discrete_states, "Discrete State", NONE(), false) +
              VariablePointers.toString(varData.clocked_states, "Clocked State", NONE(), false) +
              VariablePointers.toString(varData.previous, "Previous", NONE(), false) +
              VariablePointers.toString(varData.clocks, "Clock", NONE(), false) +
              VariablePointers.toString(varData.top_level_inputs, "Top Level Input", NONE(), false) +
              VariablePointers.toString(varData.resizables, "Resizable Parameters", NONE(), false) +
              VariablePointers.toString(varData.parameters, "Parameter", NONE(), false) +
              VariablePointers.toString(varData.constants, "Constant", NONE(), false) +
              VariablePointers.toString(varData.records, "Record", NONE(), false) +
              VariablePointers.toString(varData.external_objects, "External Object", NONE(), false) +
              VariablePointers.toString(varData.artificials, "Artificial", NONE(), false);
          end if;
          tmp := tmp + VariablePointers.toString(varData.auxiliaries, "Auxiliary", NONE(), false) +
            VariablePointers.toString(varData.aliasVars, "Alias", NONE(), false);
        then tmp;

        case VAR_DATA_JAC() algorithm
          tmp := VariablePointers.toString(varData.unknowns, "Partial Derivative", NONE(), false) +
            VariablePointers.toString(varData.seedVars, "Seed", NONE(), false);
          if full then
            tmp := tmp + VariablePointers.toString(varData.diffVars, "Differentiation", NONE(), false) +
              VariablePointers.toString(varData.resultVars, "Residual", NONE(), false) +
              VariablePointers.toString(varData.tmpVars, "Inner", NONE(), false) +
              VariablePointers.toString(varData.dependencies, "Dependencies", NONE(), false) +
              VariablePointers.toString(varData.knowns, "Known", NONE(), false) +
              VariablePointers.toString(varData.auxiliaries, "Auxiliary", NONE(), false) +
              VariablePointers.toString(varData.aliasVars, "Alias", NONE(), false);
          end if;
        then tmp;

        case VAR_DATA_HES() algorithm
          tmp := StringUtil.headline_2("Variable Data Hessian") + "\n" +
            VariablePointers.toString(varData.unknowns, "Unknown", NONE(), false) +
            VariablePointers.toString(varData.knowns, "Known", NONE(), false) +
            VariablePointers.toString(varData.auxiliaries, "Auxiliary", NONE(), false) +
            VariablePointers.toString(varData.aliasVars, "Alias", NONE(), false);
          if full then
            tmp := tmp + VariablePointers.toString(varData.diffVars, "Differentiation", NONE(), false) +
              VariablePointers.toString(varData.dependencies, "Dependencies", NONE(), false) +
              VariablePointers.toString(varData.resultVars, "Result", NONE(), false) +
              VariablePointers.toString(varData.tmpVars, "Temporary", NONE(), false) +
              VariablePointers.toString(varData.seedVars, "First Seed", NONE(), false) +
              VariablePointers.toString(varData.seedVars2, "Second Seed", NONE(), false);
              if isSome(varData.lambdaVars) then
                SOME(lambdaVars) := varData.lambdaVars;
                tmp := tmp + VariablePointers.toString(lambdaVars, "Lagrangian Lambda", NONE(), false);
              end if;
          end if;
        then tmp;

        else fail();
      end match;
    end toStringVerbose;

    function getVariables
      input VarData varData;
      output VariablePointers variables;
    algorithm
      variables := match varData
        case VAR_DATA_SIM() then varData.variables;
        case VAR_DATA_JAC() then varData.variables;
        case VAR_DATA_HES() then varData.variables;
        else fail();
      end match;
    end getVariables;

    function setVariables
      input output VarData varData;
      input VariablePointers variables;
    algorithm
      varData := match varData
        case VAR_DATA_SIM() algorithm varData.variables := variables; then varData;
        case VAR_DATA_JAC() algorithm varData.variables := variables; then varData;
        case VAR_DATA_HES() algorithm varData.variables := variables; then varData;
        else fail();
      end match;
    end setVariables;

    function getStateOrder
      input VarData varData;
      output UnorderedMap<ComponentRef, ComponentRef> state_order;
    algorithm
      state_order := match varData
        case VAR_DATA_SIM() then varData.state_order;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed because of incorrect record type."});
        then fail();
      end match;
    end getStateOrder;

    // used to add specific types. Fill up with Jacobian/Hessian types
    type VarType = enumeration(STATE, STATE_DER, ALGEBRAIC, DISCRETE, DISC_STATE, PREVIOUS, START, PARAMETER, ITERATOR, RECORD, CLOCK);

    function addTypedList
      "can also be used to add single variables"
      input output VarData varData;
      input list<Pointer<Variable>> var_lst;
      input VarType varType;
    algorithm
      varData := match (varData, varType)

        case (VAR_DATA_SIM(), VarType.STATE) algorithm
          varData.variables   := VariablePointers.addList(var_lst, varData.variables);
          varData.knowns      := VariablePointers.addList(var_lst, varData.knowns);
          varData.states      := VariablePointers.addList(var_lst, varData.states);
          varData.initials    := VariablePointers.addList(var_lst, varData.initials);
          // also remove from algebraics in the case it was moved
          varData.unknowns    := VariablePointers.removeList(var_lst, varData.unknowns);
          varData.algebraics  := VariablePointers.removeList(var_lst, varData.algebraics);
        then varData;

        case (VAR_DATA_SIM(), VarType.STATE_DER) algorithm
          varData.variables   := VariablePointers.addList(var_lst, varData.variables);
          varData.unknowns    := VariablePointers.addList(var_lst, varData.unknowns);
          varData.derivatives := VariablePointers.addList(var_lst, varData.derivatives);
          varData.initials    := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        // algebraic variables, dummy states and dummy derivatives are mathematically equal
        case (VAR_DATA_SIM(), VarType.ALGEBRAIC) algorithm
          varData.variables   := VariablePointers.addList(var_lst, varData.variables);
          varData.unknowns    := VariablePointers.addList(var_lst, varData.unknowns);
          varData.algebraics  := VariablePointers.addList(var_lst, varData.algebraics);
          varData.initials    := VariablePointers.addList(var_lst, varData.initials);
          // also remove from states/derivatives in the case it was moved
          varData.states      := VariablePointers.removeList(var_lst, varData.states);
          varData.derivatives := VariablePointers.removeList(var_lst, varData.derivatives);
          varData.knowns      := VariablePointers.removeList(var_lst, varData.knowns);
        then varData;

        case (VAR_DATA_SIM(), VarType.DISCRETE) algorithm
          varData.variables   := VariablePointers.addList(var_lst, varData.variables);
          varData.unknowns    := VariablePointers.addList(var_lst, varData.unknowns);
          varData.discretes   := VariablePointers.addList(var_lst, varData.discretes);
          varData.initials    := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        case (VAR_DATA_SIM(), VarType.START) algorithm
          varData.variables   := VariablePointers.addList(var_lst, varData.variables);
          varData.initials    := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        case (VAR_DATA_SIM(), VarType.PARAMETER) algorithm
          varData.parameters  := VariablePointers.addList(var_lst, varData.parameters);
          varData.knowns      := VariablePointers.addList(var_lst, varData.knowns);
        then varData;

        case (VAR_DATA_SIM(), VarType.ITERATOR) algorithm
          varData.variables   := VariablePointers.addList(var_lst, varData.variables);
          varData.knowns      := VariablePointers.addList(var_lst, varData.knowns);
          varData.artificials := VariablePointers.addList(var_lst, varData.artificials);
        then varData;

        case (VAR_DATA_SIM(), VarType.CLOCK) algorithm
          varData.clocks      := VariablePointers.addList(var_lst, varData.clocks);
        then varData;

        // IMPORTANT: requires the record elements to be added as children beforehand!
        case (VAR_DATA_SIM(), VarType.RECORD) algorithm
          varData.variables   := VariablePointers.addList(var_lst, varData.variables);
          varData.records     := VariablePointers.addList(var_lst, varData.records);
          varData.knowns      := VariablePointers.addList(var_lst, varData.knowns);
          varData.records     := VariablePointers.mapPtr(varData.records, function BackendDAE.lowerRecordChildren(variables = varData.variables));
        then varData;

        // ToDo: other cases

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end addTypedList;

  end VarData;

  // ==========================================================================
  //                      Protected utility functions
  // ==========================================================================
protected
  function getVarNameTraverse
    input Pointer<Variable> var;
    input Pointer<list<ComponentRef>> acc;
  algorithm
    Pointer.update(acc, getVarName(var) :: Pointer.access(acc));
  end getVarNameTraverse;

  annotation(__OpenModelica_Interface="backend");
end NBVariable;
