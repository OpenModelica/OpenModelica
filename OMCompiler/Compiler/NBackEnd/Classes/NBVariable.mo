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
  import NFBackendExtension.{BackendInfo, VariableKind, VariableAttributes};
  import NFBinding.Binding;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Scalarize = NFScalarize;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend Imports
  import NBAdjacency.Mapping;
  import BackendDAE = NBackendDAE;
  import BackendUtil = NBBackendUtil;
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
    {}, {}, NONE(), SCodeUtil.dummyInfo, NFBackendExtension.DUMMY_BACKEND_INFO);

  constant Variable TIME_VARIABLE = Variable.VARIABLE(NFBuiltin.TIME_CREF, Type.REAL(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFAttributes.DEFAULT_ATTR,
    {}, {}, NONE(), SCodeUtil.dummyInfo, BackendExtension.BACKEND_INFO(
    VariableKind.TIME(), NFBackendExtension.EMPTY_VAR_ATTR_REAL, NFBackendExtension.EMPTY_ANNOTATIONS, NONE(), NONE()));

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

  function toString
    input Variable var;
    input output String str = "";
  protected
    String attr;
  algorithm
    attr := VariableAttributes.toString(var.backendinfo.attributes);
    str := str + VariableKind.toString(var.backendinfo.varKind) + " (" + intString(Variable.size(var)) + ") " + Variable.toString(var) + (if attr == "" then "" else " " + attr);
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
    output Integer s = Variable.size(Pointer.access(var_ptr));
  end size;

  function fromCref
    input ComponentRef cref;
    input Attributes attr = NFAttributes.DEFAULT_ATTR;
    input Binding binding = NFBinding.EMPTY_BINDING;
    output Variable variable;
  protected
    InstNode node;
    Type ty;
    Prefixes.Visibility vis;
    SourceInfo info;
  algorithm
    node := ComponentRef.node(cref);
    ty   := ComponentRef.getSubscriptedType(cref, true);
    vis  := InstNode.visibility(node);
    info := InstNode.info(node);
    variable := Variable.VARIABLE(cref, ty, binding, vis, attr, {}, {}, NONE(), info, NFBackendExtension.DUMMY_BACKEND_INFO);
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

  function connectPrePostVar
    "sets the pre() var for the variable and also sets the variable pointer at the pre() variable"
    input Pointer<Variable> var_ptr;
    input Pointer<Variable> pre_ptr;
  protected
    Variable var = Pointer.access(var_ptr);
    Variable pre = Pointer.access(pre_ptr);
  algorithm
    var.backendinfo := BackendInfo.setPrePost(var.backendinfo, SOME(pre_ptr));
    pre.backendinfo := BackendInfo.setPrePost(pre.backendinfo, SOME(var_ptr));
    Pointer.update(var_ptr, var);
    Pointer.update(pre_ptr, pre);
  end connectPrePostVar;

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

  partial function checkVar
    input Pointer<Variable> var_ptr;
    output Boolean b;
  end checkVar;

  function isArray extends checkVar;
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

  function isEmpty extends checkVar;
  algorithm
    b := ComponentRef.isEmpty(getVarName(var_ptr));
  end isEmpty;

  function isState extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE())) then true;
      else false;
    end match;
  end isState;

  function isStateDerivative extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE_DER())) then true;
      else false;
    end match;
  end isStateDerivative;

  function isAlgebraic extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.ALGEBRAIC())) then true;
      else false;
    end match;
  end isAlgebraic;

  function isStart extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.START())) then true;
      else false;
    end match;
  end isStart;

  function isTime extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.TIME())) then true;
      else false;
    end match;
  end isTime;

  function isContinuous extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE_STATE()))  then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE()))        then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PREVIOUS()))        then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER()))       then false;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT()))        then false;
      else true;
    end match;
  end isContinuous;

  function isDiscreteState extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE_STATE())) then true;
      else false;
    end match;
  end isDiscreteState;

  function isDiscrete extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE())) then true;
      else false;
    end match;
  end isDiscrete;

  function isPrevious extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PREVIOUS())) then true;
      else false;
    end match;
  end isPrevious;

  function isRecord extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.RECORD())) then true;
      else false;
    end match;
  end isRecord;

  function isKnownRecord extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      local
        Boolean known;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.RECORD(known = known))) then known;
      else false;
    end match;
  end isKnownRecord;

  function getPrePost
    "gets the pre() / previous() var if its a variable / clocked variable or the other way around"
    input Pointer<Variable> var_ptr;
    output Option<Pointer<Variable>> pre_post;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    pre_post := var.backendinfo.pre_post;
  end getPrePost;

  function getPrePostCref
    "only use if you are sure there is a pre-post variable"
    input ComponentRef cref;
    output ComponentRef pre_post;
  protected
    Option<Pointer<Variable>> pre_post_opt;
  algorithm
    pre_post_opt := getPrePost(getVarPointer(cref));
    if Util.isSome(pre_post_opt) then
      pre_post := getVarName(Util.getOption(pre_post_opt));
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because it had no pre or post variable."});
      fail();
    end if;
  end getPrePostCref;

  function hasPre
    "only returns true if the variable itself is not a pre() or previous() and has a pre() pointer set"
    extends checkVar;
  algorithm
    b := not isPrevious(var_ptr) and Util.isSome(getPrePost(var_ptr));
  end hasPre;

  function isDummyState extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DUMMY_STATE())) then true;
      else false;
    end match;
  end isDummyState;

  function isDummyDer extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DUMMY_DER())) then true;
      else false;
    end match;
  end isDummyDer;

  function isParamOrConst extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER())) then true;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT())) then true;
      else false;
    end match;
  end isParamOrConst;

  function isConst extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT())) then true;
      else false;
    end match;
  end isConst;

  function isKnown extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER())) then true;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.CONSTANT())) then true;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE())) then true;
      else false;
    end match;
  end isKnown;

  function isDAEResidual extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DAE_RESIDUAL_VAR())) then true;
      else false;
    end match;
  end isDAEResidual;

  function isSeed extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.SEED_VAR())) then true;
      else false;
    end match;
  end isSeed;

  function isInput extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(attributes = Attributes.ATTRIBUTES(direction = NFPrefixes.Direction.INPUT)) then true;
      else false;
    end match;
  end isInput;

  function isOutput extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(attributes = Attributes.ATTRIBUTES(direction = NFPrefixes.Direction.OUTPUT)) then true;
      else false;
    end match;
  end isOutput;

  function isFixed extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      local
        Expression fixed;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_REAL(fixed = SOME(fixed))))         then Expression.isAllTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_INT(fixed = SOME(fixed))))          then Expression.isAllTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_BOOL(fixed = SOME(fixed))))         then Expression.isAllTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_STRING(fixed = SOME(fixed))))       then Expression.isAllTrue(fixed);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_ENUMERATION(fixed = SOME(fixed))))  then Expression.isAllTrue(fixed);
      else false;
    end match;
  end isFixed;

  function isFixable
    "states, discretes and parameters are fixable if they are not already fixed.
    discrete states are always fixable. previous vars are only fixable if the discrete state for it wasn't fixed."
    extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE()))             then not isFixed(var_ptr);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.ALGEBRAIC()))         then not isFixed(var_ptr) or hasPre(var_ptr);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE()))          then not isFixed(var_ptr) or hasPre(var_ptr);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DISCRETE_STATE()))    then not isFixed(var_ptr) or hasPre(var_ptr);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PARAMETER()))         then not isFixed(var_ptr);
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.PREVIOUS()))          then true;
      else false;
    end match;
  end isFixable;

  function isStateSelect
    "checks if a variable has a certain StateSelect attribute"
    extends checkVar;
    input BackendExtension.StateSelect stateSelect;
  algorithm
    b := match Pointer.access(var_ptr)
      local
        VariableAttributes attributes;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = attributes))
      then VariableAttributes.getStateSelect(attributes) == stateSelect;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + toString(Pointer.access(var_ptr))});
      then fail();
    end match;
  end isStateSelect;

  function getVariableAttributes
    input Variable var;
    output VariableAttributes variableAttributes = var.backendinfo.attributes;
  end getVariableAttributes;

  function setVariableAttributes
    input output Variable var;
    input VariableAttributes variableAttributes;
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
    input VariableKind varKind;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, varKind);
    Pointer.update(varPointer, var);
  end setVarKind;

  function setParent
    "sets the record parent. only do for record elements!"
    input output Pointer<Variable> varPointer;
    input Pointer<Variable> parent;
  protected
    Variable var = Pointer.access(varPointer);
  algorithm
    var.backendinfo := BackendExtension.BackendInfo.setParent(var.backendinfo, parent);
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
    b := match Pointer.access(var_ptr)
      case NFVariable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.FRONTEND_DUMMY())) then true;
      else false;
    end match;
  end isDummyVariable;

  function isFunctionAlias extends checkVar;
  algorithm
    b := StringUtil.startsWith(ComponentRef.firstName(getVarName(var_ptr)), FUNCTION_STR);
  end isFunctionAlias;

  function createTimeVar
    output Pointer<Variable> var_ptr;
  protected
    Variable var = TIME_VARIABLE;
  algorithm
    (var_ptr, _) := makeVarPtrCyclic(var, var.name);
  end createTimeVar;

  function makeStateVar
    "Updates a variable pointer to be a state, requires the pointer to its derivative."
    input Pointer<Variable> varPointer;
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
    () := match ComponentRef.node(cref)
      local
        InstNode derNode;
        Pointer<Variable> state, dummy_ptr = Pointer.create(DUMMY_VARIABLE);
        Variable var;
      case InstNode.VAR_NODE()
        algorithm
          state := getVarPointer(cref);
          // append the $DER to the name
          derNode := InstNode.VAR_NODE(DERIVATIVE_STR, dummy_ptr);
          der_cref := ComponentRef.append(cref, ComponentRef.fromNode(derNode, ComponentRef.scalarType(cref)));
          // make the actual derivative variable and make cref and the variable cyclic
          var := fromCref(ComponentRef.stripSubscriptsAll(der_cref), Variable.attributes(Pointer.access(state)));
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

  function getRecordChildren
    "returns all children of the variable if its a record, otherwise returns empty list"
    input Pointer<Variable> var;
    output list<Pointer<Variable>> children;
  algorithm
    children := match Pointer.access(var)
      local
        VariableKind varKind;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = varKind as BackendExtension.RECORD()))
      then varKind.children;
      else {};
    end match;
  end getRecordChildren;

  function makeDummyState
    input Pointer<Variable> varPointer;
    output Pointer<Variable> derivative;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := match BackendExtension.BackendInfo.getVarKind(var.backendinfo)
      local
        VariableKind varKind;
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
    input Pointer<Variable> varPointer;
  protected
    Variable var = Pointer.access(varPointer);
  algorithm
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DISCRETE_STATE(false));
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
          var_ptr := BVariable.getVarPointer(cref);
          qual.name := PREVIOUS_STR;
          pre_cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          pre := fromCref(pre_cref, Variable.attributes(Pointer.access(var_ptr)));
          pre.backendinfo := BackendExtension.BackendInfo.setVarKind(pre.backendinfo, BackendExtension.PREVIOUS());
          (pre_ptr, pre_cref) := makeVarPtrCyclic(pre, pre_cref);
          connectPrePostVar(var_ptr, pre_ptr);
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
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          // get the variable pointer from the old cref to later on link back to it
          old_var_ptr := BVariable.getVarPointer(cref);
          // prepend the seed str and the matrix name and create the new cref
          qual.name := SEED_STR + "_" + name;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(cref, NFAttributes.IMPL_DISCRETE_ATTR);
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
    input ComponentRef cref           "old component reference";
    input String name                 "name of the matrix this partial derivative belongs to";
    input Boolean isTmp               "sets variable kind for tmpVar or resultVar accordingly";
    output ComponentRef pder_cref     "new component reference";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  protected
    VariableKind varKind = if isTmp then BackendExtension.JAC_TMP_VAR() else BackendExtension.JAC_VAR();
  algorithm
    () := match ComponentRef.node(cref)
      local
        InstNode qual;
        Variable var;

      // regular case for jacobians
      case qual as InstNode.VAR_NODE() algorithm
        // prepend the seed str and the matrix name and create the new cref_DIFF_DIFF
        qual.name := PARTIAL_DERIVATIVE_STR + "_" + name;
        pder_cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
        var := fromCref(pder_cref, Variable.attributes(getVar(cref)));
        // update the variable kind and pass the pointer to the original variable
        var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, varKind);
        // create the new variable pointer and safe it to the component reference
        (var_ptr, pder_cref) := makeVarPtrCyclic(var, pder_cref);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makePDerVar;

  function makeFDerVar
      "Creates a function derivative cref. Used in NBDifferentiation
    for differentiating body vars of a function."
    input output ComponentRef cref    "old component reference to new component reference";
  algorithm
    cref := match ComponentRef.node(cref)
      local
        InstNode qual;

      // for function differentiation (crefs are not lowered and only known locally)
      case qual as InstNode.COMPONENT_NODE() algorithm
        // prepend the seed str, matrix name locally not needed
        qual.name := FUNCTION_DERIVATIVE_STR + "_" + qual.name;
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
          old_var_ptr := BVariable.getVarPointer(cref);
          // prepend the seed str and the matrix name and create the new cref
          qual.name := START_STR;
          start_cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.scalarType(cref)));
          var := fromCref(start_cref, Variable.attributes(getVar(cref)));
          // update the variable to be a seed and pass the pointer to the original variable
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.START(old_var_ptr));
          // create the new variable pointer and safe it to the component reference
          var_ptr := Pointer.create(var);
          start_cref := BackendDAE.lowerComponentReferenceInstNode(start_cref, var_ptr);
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
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DAE_RESIDUAL_VAR(uniqueIndex));

    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
  end makeResidualVar;

  function makeEventVar
    "Creates a generic boolean variable pointer from a unique index and context name.
    e.g. (\"$SEV\", 4) --> $SEV_4"
    input String name                           "context name e.g. §WHEN";
    input Integer uniqueIndex                   "unique identifier index";
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
      ty := Type.BOOLEAN();
    else
      sub_sizes := Iterator.sizes(iterator);
      ty := Type.ARRAY(Type.BOOLEAN(), list(Dimension.fromInteger(sub_size) for sub_size in sub_sizes));
    end if;
    // create inst node with dummy variable pointer and create cref from it
    node := InstNode.VAR_NODE(name + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    cref := ComponentRef.CREF(node, iter_subs, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    var_cref := ComponentRef.CREF(node, {}, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    // create variable
    var := fromCref(var_cref, NFAttributes.IMPL_DISCRETE_ATTR);
    // update the variable to be discrete and pass the pointer to the original variable
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DISCRETE());
    var.backendinfo := BackendExtension.BackendInfo.setHideResult(var.backendinfo, true);
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
  algorithm
    // create inst node with dummy variable pointer and create cref from it
    node  := InstNode.VAR_NODE(name + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    cref  := ComponentRef.CREF(node, {}, ty, NFComponentRef.Origin.CREF, ComponentRef.EMPTY());
    var   := fromCref(cref);
    // update the variable kind and set hideResult = true
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, VariableKind.fromType(ty, makeParam));
    var.backendinfo := BackendExtension.BackendInfo.setHideResult(var.backendinfo, true);

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
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.ALGEBRAIC());
    // create the new variable pointer and safe it to the component reference
    (var_ptr, cref) := makeVarPtrCyclic(var, cref);
    (der_cref, der_var) := BVariable.makeDerVar(cref);
    BVariable.makeStateVar(var_ptr, der_var);
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
      case Variable.VARIABLE(binding = Binding.TYPED_BINDING(variability = tmp))    then tmp;
      case Variable.VARIABLE(binding = Binding.FLAT_BINDING(variability = tmp))     then tmp;
      case Variable.VARIABLE(binding = Binding.UNBOUND())                           then NFPrefixes.Variability.CONTINUOUS;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding."});
      then fail();
    end match;
  end getBindingVariability;

  function hasConstBinding extends checkVar;
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
        binfo.attributes := VariableAttributes.setFixed(binfo.attributes, var.ty, b);
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
        binfo.attributes := VariableAttributes.setStartAttribute(binfo.attributes, start);
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
    var_ptr := setBindingAsStart(var_ptr);
    var_ptr := setFixed(var_ptr, b);
  end setBindingAsStartAndFix;

  function getStartAttribute
    input Pointer<Variable> var_ptr;
    output Option<Expression> start =  VariableAttributes.getStartAttribute(getVariableAttributes(Pointer.access(var_ptr)));
  end getStartAttribute;

  function hasNonTrivialAliasBinding
    "returns true if the binding does not represent a cref, a negated cref or a constant.
     used for alias removal since only those can be stored as actual alias variables"
    extends checkVar;
  protected
    Variable var;
    Expression binding;
  algorithm
    var := Pointer.access(var_ptr);
    binding := Binding.getExp(var.binding);
    b := (not Expression.isTrivialCref(binding)) and checkExpMap(binding, isTimeDependent);
  end hasNonTrivialAliasBinding;

  function hasConstOrParamAliasBinding extends checkVar;
  protected
    Variable var;
    Expression binding;
  algorithm
    var := Pointer.access(var_ptr);
    binding := Binding.getExp(var.binding);
    b := not checkExpMap(binding, isTimeDependent);
  end hasConstOrParamAliasBinding;

  function isTimeDependent extends checkVar;
  algorithm
    b := match Pointer.access(var_ptr)
      local
        Variable var;

      case var as Variable.VARIABLE()
      then VariableKind.isTimeDependent(BackendExtension.BackendInfo.getVarKind(var.backendinfo));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end isTimeDependent;

  function isBound extends checkVar;
  protected
    Variable var = Pointer.access(var_ptr);
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
    input checkVar func;
    output Boolean b;
    function checkExpTraverse
      input output Expression exp;
      input checkVar func;
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
    input checkVar func;
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
        str := StringUtil.headline_4(str + " Variables (" + intString(numberOfElements) + "/" + intString(scalarSize(variables)) + ")");
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
      list<Pointer<Variable>> vars, new_vars = {};
      list<Variable> scalar_vars, element_vars;
      Variable var;
      Boolean flattened = false;
    algorithm
      vars := toList(variables);
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

      // only change variables if any of them have been flattened
      if flattened then
        variables := fromList(listReverse(new_vars), true);
      end if;
    end scalarize;

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
      sizes := listReverse(list(Dimension.size(dim) for dim in Type.arrayDims(ty)));
      vals := Slice.indexToLocation(scal-start, sizes);
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
      VariablePointers discrete_states    "Discrete state variables";
      VariablePointers previous           "Previous variables (pre(d) -> $PRE.d)";
      // clocked

      /* subset of knowns */
      VariablePointers states             "States";
      VariablePointers top_level_inputs   "Top level inputs";
      VariablePointers parameters         "Parameters";
      VariablePointers constants          "Constants";
      VariablePointers records            "Records";
      VariablePointers artificials        "artificial variables to have pointers on crefs";
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
      output Integer s;
    algorithm
      s := match varData
        case VAR_DATA_SIM() then VariablePointers.scalarSize(varData.unknowns);
        case VAR_DATA_JAC() then VariablePointers.scalarSize(varData.unknowns);
        case VAR_DATA_HES() then VariablePointers.scalarSize(varData.unknowns);
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
          tmp := "Variable Data Simulation (scalar unknowns: " + intString(VariablePointers.scalarSize(varData.unknowns)) + ")";
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
              VariablePointers.toString(varData.discrete_states, "Discrete States", NONE(), false) +
              VariablePointers.toString(varData.previous, "Previous", NONE(), false) +
              VariablePointers.toString(varData.top_level_inputs, "Top Level Inputs", NONE(), false) +
              VariablePointers.toString(varData.parameters, "Parameter", NONE(), false) +
              VariablePointers.toString(varData.constants, "Constant", NONE(), false) +
              VariablePointers.toString(varData.records, "Record", NONE(), false) +
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

    // used to add specific types. Fill up with Jacobian/Hessian types
    type VarType = enumeration(STATE, STATE_DER, ALGEBRAIC, DISCRETE, DISC_STATE, PREVIOUS, START, PARAMETER, ITERATOR);

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

        case (VAR_DATA_SIM(), VarType.DISCRETE) algorithm
          varData.variables := VariablePointers.addList(var_lst, varData.variables);
          varData.unknowns := VariablePointers.addList(var_lst, varData.unknowns);
          varData.discretes := VariablePointers.addList(var_lst, varData.discretes);
          varData.initials := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        case (VAR_DATA_SIM(), VarType.START) algorithm
          varData.variables := VariablePointers.addList(var_lst, varData.variables);
          varData.initials := VariablePointers.addList(var_lst, varData.initials);
        then varData;

        case (VAR_DATA_SIM(), VarType.PARAMETER) algorithm
          varData.parameters := VariablePointers.addList(var_lst, varData.parameters);
          varData.knowns := VariablePointers.addList(var_lst, varData.knowns);
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
