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
  import BackendExtension = NFBackendExtension;
  import NFBackendExtension.BackendInfo;
  import NFBinding.Binding;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Scalarize = NFScalarize;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;
  import NFBackendExtension.VariableKind;

  // Backend Imports
  import BackendDAE = NBackendDAE;
  import BackendUtil = NBBackendUtil;
  import BVariable = NBVariable;

  //Util Imports
  import Array;
  import BaseHashTable;
  import ExpandableArray;
  import StringUtil;
  import UnorderedMap;
  import Util;

public
  type VariablePointer = Pointer<Variable> "mainly used for mapping purposes";

  // ==========================================================================
  //               Single Variable constants and functions
  // ==========================================================================
  constant Variable DUMMY_VARIABLE = Variable.VARIABLE(ComponentRef.EMPTY(), Type.ANY(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFComponent.DEFAULT_ATTR,
    {}, {}, NONE(), SCodeUtil.dummyInfo, NFBackendExtension.DUMMY_BACKEND_INFO);

  constant Variable TIME_VARIABLE = Variable.VARIABLE(NFBuiltin.TIME_CREF, Type.REAL(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFComponent.DEFAULT_ATTR,
    {}, {}, NONE(), SCodeUtil.dummyInfo, BackendExtension.BACKEND_INFO(
    BackendExtension.VariableKind.TIME(), NFBackendExtension.EMPTY_VAR_ATTR_REAL));

  constant String DERIVATIVE_STR          = "$DER";
  constant String DUMMY_DERIVATIVE_STR    = "$dDER";
  constant String PARTIAL_DERIVATIVE_STR  = "$pDER";
  constant String FUNCTION_DERIVATIVE_STR = "$fDER";
  constant String PREVIOUS_STR            = "$PRE";
  constant String AUXILIARY_STR           = "$AUX";
  constant String START_STR               = "$START";
  constant String RESIDUAL_STR            = "$RES";
  constant String TEMPORARY_STR           = "$TMP";
  constant String SEED_STR                = "$SEED";
  constant String TIME_EVENT_STR          = "$TEV";
  constant String STATE_EVENT_STR         = "$SEV";

  function toString
    input Variable var;
    input output String str = "";
  protected
    String attr;
  algorithm
    attr := BackendExtension.VariableAttributes.toString(var.backendinfo.attributes);
    str := str + VariableKind.toString(var.backendinfo.varKind) + " (" + intString(Variable.size(var)) + ") " + Variable.toString(var) + (if attr == "" then "" else " " + attr);
  end toString;

  function pointerToString
    input Pointer<Variable> var_ptr;
    output String str = toString(Pointer.access(var_ptr));
  end pointerToString;

  function hash
    input Pointer<Variable> var_ptr;
    input Integer mod;
    output Integer i = Variable.hash(Pointer.access(var_ptr), mod);
  end hash;

  function equalName
    input Pointer<Variable> var_ptr1;
    input Pointer<Variable> var_ptr2;
    output Boolean b = Variable.equalName(Pointer.access(var_ptr1), Pointer.access(var_ptr2));
  end equalName;

  function size
    input Pointer<Variable> var_ptr;
    output Integer s = Variable.size(Pointer.access(var_ptr));
  end size;

  function fromCref
    input ComponentRef cref;
    input Binding binding = NFBinding.EMPTY_BINDING;
    output Variable variable;
  protected
    InstNode node;
    Type ty;
    Prefixes.Visibility vis;
    SourceInfo info;
  algorithm
    node := ComponentRef.node(cref);
    ty := ComponentRef.getSubscriptedType(cref, true);
    vis := InstNode.visibility(node);
    info := InstNode.info(node);
    variable := Variable.VARIABLE(cref, ty, binding, vis, NFComponent.DEFAULT_ATTR, {}, {}, NONE(), info, NFBackendExtension.DUMMY_BACKEND_INFO);
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

  function getVar
    input ComponentRef cref;
    output Variable var;
  algorithm
    var := Pointer.access(getVarPointer(cref));
  end getVar;

  // The following functions provide layers of protection. Whenever accessing names or pointers use these!
  function getVarPointer
    input ComponentRef cref;
    output Pointer<Variable> var;
  algorithm
    var := match cref
      local
        Pointer<Variable> varPointer;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = varPointer)) then varPointer;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) +
        ", because of wrong InstNode (not VAR_NODE). Show lowering errors with -d=failtrace."});
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

  function toExpression
    input Pointer<Variable> var_ptr;
    output Expression exp = Expression.fromCref(getVarName(var_ptr));
  end toExpression;

  function isArray
    input Pointer<Variable> var_ptr;
    output Boolean b;
  protected
    Variable var = Pointer.access(var_ptr);
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
    input Pointer<Variable> var_ptr;
    output Boolean b = ComponentRef.isEmpty(getVarName(var_ptr));
  end isEmpty;

  function isState
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE())) then true;
      else false;
    end match;
  end isState;

  function isNonState
    "Seems trivial but is necessary for traversal functions"
    input Pointer<Variable> var;
    output Boolean b = not isState(var);
  end isNonState;

  function isStateDerivative
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE_DER())) then true;
      else false;
    end match;
  end isStateDerivative;

  function isAlgebraic
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.ALGEBRAIC())) then true;
      else false;
    end match;
  end isAlgebraic;

  function isStart
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.START())) then true;
      else false;
    end match;
  end isStart;

  function isTime
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.TIME())) then true;
      else false;
    end match;
  end isTime;

  function isContinuous
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE_STATE())) then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE())) then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PREVIOUS())) then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER())) then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT())) then false;
      else true;
    end match;
  end isContinuous;

  function isDiscreteState
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE_STATE())) then true;
      else false;
    end match;
  end isDiscreteState;

  function isDiscrete
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE())) then true;
      else false;
    end match;
  end isDiscrete;

  function isPrevious
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PREVIOUS())) then true;
      else false;
    end match;
  end isPrevious;

  function isDummyState
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DUMMY_STATE())) then true;
      else false;
    end match;
  end isDummyState;

  function isDummyDer
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DUMMY_DER())) then true;
      else false;
    end match;
  end isDummyDer;

  function isParamOrConst
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER())) then true;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT())) then true;
      else false;
    end match;
  end isParamOrConst;

  function isConst
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT())) then true;
      else false;
    end match;
  end isConst;

  function isKnown
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER())) then true;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT())) then true;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE())) then true;
      else false;
    end match;
  end isKnown;

  function isDAEResidual
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DAE_RESIDUAL_VAR())) then true;
      else false;
    end match;
  end isDAEResidual;

  function isSeed
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.SEED_VAR())) then true;
      else false;
    end match;
  end isSeed;

  function isInput
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      local
        Component.Direction direction;
      case Variable.VARIABLE(attributes = Component.Attributes.ATTRIBUTES(direction = NFComponent.Direction.INPUT)) then true;
      else false;
    end match;
  end isInput;

  function isOutput
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      local
        Component.Direction direction;
      case Variable.VARIABLE(attributes = Component.Attributes.ATTRIBUTES(direction = NFComponent.Direction.OUTPUT)) then true;
      else false;
    end match;
  end isOutput;

  function isFixed
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      local
        Expression fixed;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_REAL(fixed = SOME(fixed))))         then Expression.isTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_INT(fixed = SOME(fixed))))          then Expression.isTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_BOOL(fixed = SOME(fixed))))         then Expression.isTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_STRING(fixed = SOME(fixed))))       then Expression.isTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_ENUMERATION(fixed = SOME(fixed))))  then Expression.isTrue(fixed);
      else false;
    end match;
  end isFixed;

  function isFixable
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE()))       then not isFixed(var);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE()))    then not isFixed(var);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER()))   then not isFixed(var);
      else false;
    end match;
  end isFixable;

  function isStateSelect
    "checks if a variable has a certain StateSelect attribute"
    input Pointer<Variable> var;
    input BackendExtension.StateSelect stateSelect;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      local
        BackendExtension.VariableAttributes attributes;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = attributes))
      then BackendExtension.VariableAttributes.getStateSelect(attributes) == stateSelect;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + toString(Pointer.access(var))});
      then fail();
    end match;
  end isStateSelect;

  function setVariableAttributes
    input output Variable var;
    input BackendExtension.VariableAttributes variableAttributes;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo backendinfo;
      case NFVariable.VARIABLE(backendinfo = backendinfo) algorithm
        backendinfo.attributes := variableAttributes;
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setVariableAttributes;

  function setVarKind
    "use with caution: some variable kinds have extra information that needs to be correct"
    input output Pointer<Variable> varPointer;
    input BackendExtension.VariableKind varKind;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, varKind);
    Pointer.update(varPointer, var);
  end setVarKind;

  function isDummyVariable
    "Returns true, if the variable is a dummy variable.
    Note: !Only works in the backend, will return true for any variable if used
    during frontend!"
    input Variable var;
    output Boolean isDummy;
  algorithm
    isDummy := match var
      case NFVariable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.FRONTEND_DUMMY())) then true;
      else false;
    end match;
  end isDummyVariable;

  function createTimeVar
    output Pointer<Variable> varPointer;
  protected
    Variable var = TIME_VARIABLE;
  algorithm
    (varPointer, _) := makeVarPtrCyclic(var, var.name);
  end createTimeVar;

  function makeStateVar
    "Updates a variable pointer to be a state, requires the pointer to its derivative."
    input output Pointer<Variable> varPointer;
    input Pointer<Variable> derivative;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.STATE(1, SOME(derivative), true));
    Pointer.update(varPointer, var);
  end makeStateVar;

  function makeAlgStateVar
    "Updates a variable pointer to be an algebraic state.
    Only if it currently is an algebraic variable, required for DAEMode."
    input Pointer<Variable> varPointer;
  protected
    Variable var;
  algorithm
    if isAlgebraic(varPointer) then
      var := Pointer.access(varPointer);
      var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.ALG_STATE());
      Pointer.update(varPointer, var);
    end if;
  end makeAlgStateVar;

  function makeDerVar
    "Creates a derivative variable pointer from the state cref.
    e.g. height -> $DER.height"
    input ComponentRef cref           "old component reference";
    output ComponentRef der_cref      "new component reference";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    _ := match ComponentRef.node(cref)
      local
        InstNode derNode;
        Pointer<Variable> state, dummy_ptr = Pointer.create(DUMMY_VARIABLE);
        Variable var;
      case InstNode.VAR_NODE()
        algorithm
          state := getVarPointer(cref);
          derNode := InstNode.VAR_NODE(DERIVATIVE_STR, dummy_ptr);
          der_cref := ComponentRef.append(cref, ComponentRef.fromNode(derNode, ComponentRef.scalarType(cref)));
          var := fromCref(der_cref);
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.STATE_DER(state, NONE()));
          (var_ptr, der_cref) := makeVarPtrCyclic(var, der_cref);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeDerVar;

  function getStateVar
    input Pointer<Variable> der_var;
    output Pointer<Variable> state_var;
  algorithm
    state_var := match Pointer.access(der_var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE_DER(state = state_var)))
      then state_var;
      else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + pointerToString(der_var) + " because of wrong variable kind."});
        then fail();
    end match;
  end getStateVar;

  function getStateCref
    "Returns the state variable component reference from a state derivative component reference.
    Only works after the state has been detected by the DetectStates module and fails for non-state derivative crefs!"
    input output ComponentRef cref;
  algorithm
    cref := match cref
      local
        Pointer<Variable> state, derivative;
        Variable stateVar;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = derivative)) then match Pointer.access(derivative)
        case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE_DER(state = state)))
          algorithm
            stateVar := Pointer.access(state);
        then stateVar.name;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong variable kind."});
        then fail();
      end match;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong InstNode type."});
      then fail();
    end match;
  end getStateCref;

  function getDerVar
    input Pointer<Variable> state_var;
    output Pointer<Variable> der_var;
  algorithm
    der_var := match Pointer.access(state_var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE(derivative = SOME(der_var))))
      then der_var;
      else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + pointerToString(state_var) + " because of wrong variable kind."});
        then fail();
    end match;
  end getDerVar;

  function getDerCref
    "Returns the derivative variable component reference from a state component reference.
    Only works after the state has been detected by the DetectStates module and fails for non-state crefs!"
    input output ComponentRef cref;
  algorithm
    cref := match cref
      local
        Pointer<Variable> state, derivative;
        Variable derVar;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = state)) then match Pointer.access(state)
        case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE(derivative = SOME(derivative))))
          algorithm
            derVar := Pointer.access(derivative);
        then derVar.name;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong variable kind."});
        then fail();
      end match;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong InstNode type."});
      then fail();
    end match;
  end getDerCref;

  function makeDummyState
    input Pointer<Variable> varPointer;
    output Pointer<Variable> derivative;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := match BackendExtension.BackendInfo.getVarKind(var.backendinfo)
      local
        BackendExtension.VariableKind varKind;
        Variable der_var;

      case varKind as BackendExtension.STATE(derivative = SOME(derivative)) algorithm
        // also update the derivative to be a dummy derivative
        der_var := Pointer.access(derivative);
        der_var.backendinfo := BackendExtension.BackendInfo.setVarKind(der_var.backendinfo, BackendExtension.DUMMY_DER(varPointer));
        Pointer.update(derivative, der_var);
      then BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DUMMY_STATE(derivative));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(getVarName(varPointer)) + "."});
      then fail();
    end match;
    Pointer.update(varPointer, var);
  end makeDummyState;

  function getDummyDerCref
    "Returns the dummy derivative variable component reference from a dummy state component reference.
    Only works after the dummy state has been created by the IndexReduction module and fails for non-dummy-state crefs!"
    input output ComponentRef cref;
  algorithm
    cref := match cref
      local
        Pointer<Variable> dummy_state, dummy_derivative;
        Variable dummy_derVar;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = dummy_state)) then match Pointer.access(dummy_state)
        case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DUMMY_STATE(dummy_der = dummy_derivative)))
          algorithm
            dummy_derVar := Pointer.access(dummy_derivative);
        then dummy_derVar.name;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong variable kind."});
        then fail();
      end match;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong InstNode type."});
      then fail();
    end match;
  end getDummyDerCref;

  function makeDiscreteStateVar
    "Updates a discrete variable pointer to be a discrete state, requires the pointer to its left limit (pre) variable."
    input output Pointer<Variable> varPointer;
    input Pointer<Variable> previous;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DISCRETE_STATE(previous, false));
    Pointer.update(varPointer, var);
  end makeDiscreteStateVar;

  function makePreVar
    "Creates a previous variable pointer from the discrete variable cref.
    e.g. isOpen -> $PRE.isOpen"
    input output ComponentRef cref    "old component reference to new component reference";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    _ := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> disc;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          disc := BVariable.getVarPointer(cref);
          qual.name := PREVIOUS_STR;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(cref);
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.PREVIOUS(disc));
          (var_ptr, cref) := makeVarPtrCyclic(var, cref);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makePreVar;

  function getPreCref
    "Returns the previous variable component reference from a discrete componet reference.
    Only works after the discrete state has been detected by the DetectStates module and fails for non-discrete-state crefs!"
    input output ComponentRef cref;
  algorithm
    cref := match cref
      local
        Pointer<Variable> disc, previous;
        Variable preVar;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = disc)) then match Pointer.access(disc)
        case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE_STATE(previous = previous)))
          algorithm
            preVar := Pointer.access(previous);
        then preVar.name;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong variable kind."});
        then fail();
      end match;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of wrong InstNode type."});
      then fail();
    end match;
  end getPreCref;

  function makeSeedVar
    "Creates a seed variable pointer from a cref. Used in NBJacobian and NBHessian
    to represent generic gradient equations.
    e.g: (speed, 'Jac') -> $SEED_Jac.speed"
    input output ComponentRef cref    "old component reference to new component reference";
    input String name                 "name of the matrix this seed belongs to";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    _ := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> old_var_ptr;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          // get the variable pointer from the old cref to later on link back to it
          old_var_ptr := BVariable.getVarPointer(cref);
          // prepend the seed str and the matrix name and create the new cref
          qual.name := SEED_STR + "_" + name;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(cref);
          // update the variable to be a seed and pass the pointer to the original variable
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.SEED_VAR(old_var_ptr));
          // create the new variable pointer and safe it to the component reference
          (var_ptr, cref) := makeVarPtrCyclic(var, cref);
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
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    _ := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> old_var_ptr;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          // get the variable pointer from the old cref to later on link back to it
          old_var_ptr := BVariable.getVarPointer(cref);
          // prepend the seed str and the matrix name and create the new cref_DIFF_DIFF
          qual.name := PARTIAL_DERIVATIVE_STR + "_" + name;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(cref);
          // update the variable to be a jac var and pass the pointer to the original variable
          // ToDo: tmps will get JAC_DIFF_VAR !
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.JAC_VAR());
          // create the new variable pointer and safe it to the component reference
          (var_ptr, cref) := makeVarPtrCyclic(var, cref);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makePDerVar;

  function makeStartVar
    "Creates a start variable pointer from a cref. Used in NBInitialization.
    e.g: angle -> $START.angle"
    input output ComponentRef cref    "old component reference to new component reference";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    _ := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> old_var_ptr;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          // get the variable pointer from the old cref to later on link back to it
          old_var_ptr := BVariable.getVarPointer(cref);
          // prepend the seed str and the matrix name and create the new cref
          qual.name := START_STR;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(cref);
          // update the variable to be a seed and pass the pointer to the original variable
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.START(old_var_ptr));
          // create the new variable pointer and safe it to the component reference
          var_ptr := Pointer.create(var);
          cref := BackendDAE.lowerComponentReferenceInstNode(cref, var_ptr);
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
    cref := ComponentRef.CREF(node, {}, ty, NFComponentRef.Origin.SCOPE, ComponentRef.EMPTY());
    // create variable and set its kind to dae_residual (change name?)
    var := fromCref(cref);
    // update the variable to be a seed and pass the pointer to the original variable
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DAE_RESIDUAL_VAR(uniqueIndex));

    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
  end makeResidualVar;

  function makeEventVar
    "Creates a generic boolean variable pointer from a unique index and context name.
    e.g. (\"$WHEN\", 4) --> $WHEN_4"
    input String name                 "context name e.g. §WHEN";
    input Integer uniqueIndex         "unique identifier index";
    output Pointer<Variable> var_ptr  "pointer to new variable";
    output ComponentRef cref          "new component reference";
  protected
    InstNode node;
    Variable var;
  algorithm
    // create inst node with dummy variable pointer and create cref from it
    node := InstNode.VAR_NODE(name + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    cref := ComponentRef.CREF(node, {}, Type.BOOLEAN(), NFComponentRef.Origin.SCOPE, ComponentRef.EMPTY());
    // create variable and set its kind to dae_residual (change name?)
    var := fromCref(cref);
    // update the variable to be a seed and pass the pointer to the original variable
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DISCRETE());
    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
  end makeEventVar;

  function makeAuxStateVar
    "Creates a generic boolean variable pointer from a unique index and context name.
    e.g. (\"$WHEN\", 4) --> $WHEN_4"
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
    cref := ComponentRef.CREF(node, {}, Type.REAL(), NFComponentRef.Origin.SCOPE, ComponentRef.EMPTY());
    // create variable and add optional binding
    if isSome(binding) then
      bnd := Util.getOption(binding);
      var := fromCref(cref, Binding.FLAT_BINDING(bnd, Expression.variability(bnd), NFBinding.Source.BINDING));
    else
      var := fromCref(cref);
    end if;
    // update the variable to be a seed and pass the pointer to the original variable
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.ALGEBRAIC());
    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
    (der_cref, der_var) := BVariable.makeDerVar(cref);
    var_ptr := BVariable.makeStateVar(var_ptr, der_var);
  end makeAuxStateVar;

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
      case Variable.VARIABLE(binding = Binding.TYPED_BINDING(variability = tmp))  then tmp;
      case Variable.VARIABLE(binding = Binding.UNBOUND()) then NFPrefixes.Variability.CONTINUOUS;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding."});
      then fail();
    end match;
  end getBindingVariability;

  function hasConstBinding
    input Pointer<Variable> var_ptr;
    output Boolean b;
  protected
    Variable var;
  algorithm
    var := Pointer.access(var_ptr);
    b := Expression.isConstNumber(Binding.getExp(var.binding));
  end hasConstBinding;

  function setFixed
    input output Pointer<Variable> var_ptr;
    input Boolean b = true;
  protected
    Variable var;
  algorithm
    var := Pointer.access(var_ptr);
    var:= match var
      local
        BackendExtension.BackendInfo binfo;
        Expression start;

      case Variable.VARIABLE(backendinfo = binfo as BackendExtension.BACKEND_INFO()) algorithm
        binfo.attributes := BackendExtension.VariableAttributes.setFixed(binfo.attributes, b);
        var.backendinfo := binfo;
      then var;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding."});
      then fail();
    end match;
    Pointer.update(var_ptr, var);
  end setFixed;

  function setBindingAsStartAndFix
    "use this if a binding is found out to be constant, remove variable to known vars (param/const)
    NOTE: this overwrites the old start value. throw error/warning if different?"
    input output Pointer<Variable> var_ptr;
  protected
    Variable var;
  algorithm
    var := Pointer.access(var_ptr);
    var:= match var
      local
        BackendExtension.BackendInfo binfo;
        Expression start;

      case Variable.VARIABLE(backendinfo = binfo as BackendExtension.BACKEND_INFO()) algorithm
        start := Binding.getExp(var.binding);
        binfo.attributes := BackendExtension.VariableAttributes.setStartAttribute(binfo.attributes, start);
        binfo.attributes := BackendExtension.VariableAttributes.setFixed(binfo.attributes);
        var.backendinfo := binfo;
      then var;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding."});
      then fail();
    end match;
    Pointer.update(var_ptr, var);
  end setBindingAsStartAndFix;

  function hasNonTrivialAliasBinding
    "returns true if the binding does not represent a cref, a negated cref or a constant.
     used for alias removal since only those can be stored as actual alias variables"
    input Pointer<Variable> var_ptr;
    output Boolean b;
  protected
    Variable var;
    Expression binding;
  algorithm
    var := Pointer.access(var_ptr);
    binding := Binding.getExp(var.binding);
    b := not (Expression.isCref(binding) or Expression.isCref(Expression.negate(binding)));
    b := b and checkExpMap(binding, isTimeDependent);
  end hasNonTrivialAliasBinding;

  function hasConstOrParamAliasBinding
    input Pointer<Variable> var_ptr;
    output Boolean b;
  protected
    Variable var;
    Expression binding;
  algorithm
    var := Pointer.access(var_ptr);
    binding := Binding.getExp(var.binding);
    b := not checkExpMap(binding, isTimeDependent);
  end hasConstOrParamAliasBinding;

  function isTimeDependent
    input Pointer<Variable> var_ptr;
    output Boolean b;
  algorithm
    b := match Pointer.access(var_ptr)
      local
        Variable var;

      case var as Variable.VARIABLE()
      then BackendExtension.VariableKind.isTimeDependent(BackendExtension.BackendInfo.getVarKind(var.backendinfo));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end isTimeDependent;

  // ==========================================================================
  //                        Other type wrappers
  //
  // ==========================================================================

  partial function checkFunc
    input Pointer<Variable> var;
    output Boolean b;
  end checkFunc;

  function checkExp
    input Expression exp;
    input checkFunc func;
    output Boolean b;
  algorithm
    b := match exp
      local
        ComponentRef cref;
      case Expression.CREF(cref = cref)
      then func(getVarPointer(cref));
      else false;
    end match;
  end checkExp;

  function checkExpMap
    input Expression exp;
    input checkFunc func;
    output Boolean b;
    function checkExpTraverse
      input output Expression exp;
      input checkFunc func;
      input output Boolean b;
    algorithm
      if not b then
        b := checkExp(exp, func);
      end if;
    end checkExpTraverse;
  algorithm
    (_, b) := Expression.mapFold(exp, function checkExpTraverse(func=func), false);
  end checkExpMap;

  function checkCref
    input ComponentRef cref;
    input checkFunc func;
    output Boolean b = func(getVarPointer(cref));
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
      input Boolean printEmpty = true;
    protected
      Integer numberOfElements = VariablePointers.size(variables);
      Integer length = 10;
      String index;
    algorithm
      if printEmpty or numberOfElements > 0 then
        str := StringUtil.headline_4(str + " Variables (" + intString(numberOfElements) + "/" + intString(scalarSize(variables)) + ")");
        for i in 1:numberOfElements loop
          index := "(" + intString(i) + ")";
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
      output VariablePointers new = fromList(toList(variables));
    end clone;

    function size
      "returns the number of elements, not the actual scalarized number of variables!"
      input VariablePointers variables;
      output Integer sz = ExpandableArray.getNumberOfElements(variables.varArr);
    end size;

    function scalarSize
      "returns the scalar size."
      input VariablePointers variables;
      output Integer sz = 0;
    algorithm
      for var_ptr in toList(variables) loop
        sz := sz + BVariable.size(var_ptr);
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
      _ := match UnorderedMap.get(var.name, variables.map)
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
      _ := match UnorderedMap.get(var.name, variables.map)
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
      output Pointer<Variable> var_ptr;
    protected
      Integer index;
    algorithm
      var_ptr := match UnorderedMap.get(cref, variables.map)
        case SOME(index) guard(index > 0) then ExpandableArray.get(index, variables.varArr);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
        then fail();
      end match;
    end getVarSafe;

    function getVarIndex
      "Returns -1 if cref was deleted or cannot be found."
      input VariablePointers variables;
      input ComponentRef cref;
      output Integer index;
    algorithm
      index := match UnorderedMap.get(cref, variables.map)
        case SOME(index) then index;
        case NONE() then -1;
      end match;
    end getVarIndex;

    function contains
      "Returns true if the variable is in the variable pointer array."
      input Pointer<Variable> var;
      input VariablePointers variables;
      output Boolean b = getVarIndex(variables, getVarName(var)) > 0;
    end contains;

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
      input output VariablePointers vars;
    protected
      Integer numberOfElements = MetaModelica.Dangerous.arrayGetNoBoundsChecking(vars.varArr.numberOfElements, 1);
      Integer lastUsedIndex = MetaModelica.Dangerous.arrayGetNoBoundsChecking(vars.varArr.lastUsedIndex, 1);
      array<Option<Pointer<Variable>>> data = ExpandableArray.getData(vars.varArr);
      Integer i = 0;
      Pointer<Variable> moved_var;
    algorithm
      while lastUsedIndex > numberOfElements loop
        i := i + 1;
        if isNone(MetaModelica.Dangerous.arrayGetNoBoundsChecking(data, i)) then
          // update the array element which is NONE()
          SOME(moved_var) := MetaModelica.Dangerous.arrayGetNoBoundsChecking(data, lastUsedIndex);
          MetaModelica.Dangerous.arrayUpdateNoBoundsChecking(data, i, SOME(moved_var));
          // update the last element which got moved
          MetaModelica.Dangerous.arrayUpdateNoBoundsChecking(data, lastUsedIndex, NONE());
          // update the last used index until an element is found
          while isNone(MetaModelica.Dangerous.arrayGetNoBoundsChecking(data, lastUsedIndex)) loop
            lastUsedIndex := lastUsedIndex-1;
          end while;
          // udpate hash table element
          UnorderedMap.add(getVarName(moved_var), i, vars.map);
        end if;
      end while;
      MetaModelica.Dangerous.arrayUpdateNoBoundsChecking(vars.varArr.lastUsedIndex, 1, lastUsedIndex);
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
      list<Pointer<Variable>> vars, new_vars = {};
      list<Variable> scalar_vars;
      Variable var;
      Boolean anyArr;
    algorithm
      vars := toList(variables);
      for var_ptr in vars loop
        var := Pointer.access(var_ptr);
        if Type.isArray(var.ty) then
          anyArr := true;
          scalar_vars := Scalarize.scalarizeVariable(var);
          for scalar_var in listReverse(scalar_vars) loop
            // create new pointers for the scalar variables
            new_vars := Pointer.create(scalar_var) :: new_vars;
          end for;
        else
          // preserve original variable pointers
          new_vars := var_ptr :: new_vars;
        end if;
      end for;

      // only change variables if any of them was an array
      if anyArr then
        variables := fromList(listReverse(new_vars), true);
      end if;
    end scalarize;

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
      hash := stringHashDjb2Mod(BackendExtension.BackendInfo.toString(var.backendinfo), mod);
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
      VariablePointers nonTrivialAlias    "Variables removed due to alias removal";

      /* subset of unknowns */
      VariablePointers derivatives        "State derivatives (der(x) -> $DER.x)";
      VariablePointers algebraics         "Algebraic variables";
      VariablePointers discretes          "Discrete variables";
      VariablePointers previous           "Previous discrete variables (pre(d) -> $PRE.d)";

      /* subset of knowns */
      VariablePointers states             "States";
      VariablePointers parameters         "Parameters";
      VariablePointers constants          "Constants";
    end VAR_DATA_SIM;

    record VAR_DATA_JAC
      "Only to be used for Jacobians."
      VariablePointers variables          "All jacobian variables";
      /* subset of full variable array */
      VariablePointers unknowns           "All result and temporary vars";
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
      VariablePointers variables                 "All hessian variables";
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
          tmp := StringUtil.headline_2("Variable Data Simulation") + "\n";
          if not full then
            tmp := tmp + VariablePointers.toString(varData.unknowns, "Unknown", false) +
              VariablePointers.toString(varData.states, "Local Known", false) +
              VariablePointers.toString(varData.knowns, "Global Known", false);
          else
            tmp := tmp + VariablePointers.toString(varData.states, "State", false) +
              VariablePointers.toString(varData.derivatives, "Derivative", false) +
              VariablePointers.toString(varData.algebraics, "Algebraic", false) +
              VariablePointers.toString(varData.discretes, "Discrete", false) +
              VariablePointers.toString(varData.previous, "Previous", false) +
              VariablePointers.toString(varData.parameters, "Parameter", false) +
              VariablePointers.toString(varData.constants, "Constant", false);
          end if;
          tmp := tmp + VariablePointers.toString(varData.auxiliaries, "Auxiliary", false) +
            VariablePointers.toString(varData.aliasVars, "Alias", false);
        then tmp;

        case VAR_DATA_JAC() algorithm
          tmp := StringUtil.headline_2("Variable Data Jacobian") + "\n" +
            VariablePointers.toString(varData.unknowns, "Unknown", false) +
            VariablePointers.toString(varData.knowns, "Known", false) +
            VariablePointers.toString(varData.auxiliaries, "Auxiliary", false) +
            VariablePointers.toString(varData.aliasVars, "Alias", false);
          if full then
            tmp := tmp + VariablePointers.toString(varData.diffVars, "Differentiation", false) +
              VariablePointers.toString(varData.dependencies, "Dependencies", false) +
              VariablePointers.toString(varData.resultVars, "Result", false) +
              VariablePointers.toString(varData.tmpVars, "Temporary", false) +
              VariablePointers.toString(varData.seedVars, "Seed", false);
          end if;
        then tmp;

        case VAR_DATA_HES() algorithm
          tmp := StringUtil.headline_2("Variable Data Hessian") + "\n" +
            VariablePointers.toString(varData.unknowns, "Unknown", false) +
            VariablePointers.toString(varData.knowns, "Known", false) +
            VariablePointers.toString(varData.auxiliaries, "Auxiliary", false) +
            VariablePointers.toString(varData.aliasVars, "Alias", false);
          if full then
            tmp := tmp + VariablePointers.toString(varData.diffVars, "Differentiation", false) +
              VariablePointers.toString(varData.dependencies, "Dependencies", false) +
              VariablePointers.toString(varData.resultVars, "Result", false) +
              VariablePointers.toString(varData.tmpVars, "Temporary", false) +
              VariablePointers.toString(varData.seedVars, "First Seed", false) +
              VariablePointers.toString(varData.seedVars2, "Second Seed", false);
              if isSome(varData.lambdaVars) then
                SOME(lambdaVars) := varData.lambdaVars;
                tmp := tmp + VariablePointers.toString(lambdaVars, "Lagrangian Lambda", false);
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
        local
          VariablePointers tmp;
        case VAR_DATA_SIM(variables = tmp) then tmp;
        case VAR_DATA_JAC(variables = tmp) then tmp;
        case VAR_DATA_HES(variables = tmp) then tmp;
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

    // used to add specific types. Fill up with Jacobian/Hessian types
    type VarType = enumeration(STATE, STATE_DER, ALGEBRAIC, DISCRETE, DISC_STATE, PREVIOUS, START, ITERATOR);

    function addTypedList
      input output VarData varData;
      input list<Pointer<Variable>> var_lst;
      input VarType varType;
    algorithm
      varData := match (varData, varType)

        case (VAR_DATA_SIM(), VarType.STATE) algorithm
          varData.variables := VariablePointers.addList(var_lst, varData.variables);
          varData.knowns := VariablePointers.addList(var_lst, varData.knowns);
          varData.states := VariablePointers.addList(var_lst, varData.states);
          varData.initials := VariablePointers.addList(var_lst, varData.initials);
          // also remove from algebraics in the case it was moved
          varData.unknowns := VariablePointers.removeList(var_lst, varData.unknowns);
          varData.algebraics := VariablePointers.removeList(var_lst, varData.algebraics);
        then varData;

        case (VAR_DATA_SIM(), VarType.STATE_DER) algorithm
          varData.variables := VariablePointers.addList(var_lst, varData.variables);
          varData.unknowns := VariablePointers.addList(var_lst, varData.unknowns);
          varData.derivatives := VariablePointers.addList(var_lst, varData.derivatives);
          varData.initials := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        // algebraic variables, dummy states and dummy derivatives are mathematically equal
        case (VAR_DATA_SIM(), VarType.ALGEBRAIC) algorithm
          varData.variables := VariablePointers.addList(var_lst, varData.variables);
          varData.unknowns := VariablePointers.addList(var_lst, varData.unknowns);
          varData.algebraics := VariablePointers.addList(var_lst, varData.algebraics);
          varData.initials := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        case (VAR_DATA_SIM(), VarType.START) algorithm
          varData.variables := VariablePointers.addList(var_lst, varData.variables);
          varData.initials := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        case (VAR_DATA_SIM(), VarType.ITERATOR) algorithm
          varData.variables := VariablePointers.addList(var_lst, varData.variables);
          varData.knowns := VariablePointers.addList(var_lst, varData.knowns);
        then varData;

        // ToDo: other cases

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
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
