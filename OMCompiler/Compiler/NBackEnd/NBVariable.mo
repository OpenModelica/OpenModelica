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
  import BackendInfo = NFBackendExtension.BackendInfo;
  import Binding = NFBinding.Binding;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import InstNode = NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Type = NFType;
  import Variable = NFVariable;
  import VariableKind = NFBackendExtension.VariableKind;

  // Backend Imports
  import BackendDAE = NBackendDAE;
  import BackendUtil = NBBackendUtil;
  import HashTableCrToInt = NBHashTableCrToInt;
  import BVariable = NBVariable;

  //Util Imports
  import Array;
  import BaseHashTable;
  import ExpandableArray;
  import Flags;
  import StringUtil;
  import Util;

public
  // ==========================================================================
  //               Single Variable constants and functions
  // ==========================================================================
  constant Variable DUMMY_VARIABLE = Variable.VARIABLE(ComponentRef.EMPTY(), Type.ANY(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFComponent.DEFAULT_ATTR,
    {}, NONE(), SCodeUtil.dummyInfo, NFBackendExtension.DUMMY_BACKEND_INFO);

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

  function toString
    input Variable var;
    output String str;
  algorithm
    str := VariableKind.toString(var.backendinfo.varKind) + " " + Variable.toString(var) + " " + BackendExtension.VariableAttributes.toString(var.backendinfo.attributes);
  end toString;

  function fromCref
    input ComponentRef cref;
    output Variable variable;
  protected
    InstNode node;
    Type ty;
    Binding binding;
    Prefixes.Visibility vis;
    SourceInfo info;
  algorithm
    node := ComponentRef.node(cref);
    ty := ComponentRef.getSubscriptedType(cref);
    vis := InstNode.visibility(node);
    info := InstNode.info(node);
    variable := Variable.VARIABLE(cref, ty, NFBinding.EMPTY_BINDING, vis, NFComponent.DEFAULT_ATTR, {}, NONE(), info, NFBackendExtension.DUMMY_BACKEND_INFO);
  end fromCref;

  function getVar
    input ComponentRef cref;
    output Variable var;
  algorithm
    var := Pointer.access(getVarPointer(cref));
  end getVar;

  function getVarPointer
    input ComponentRef cref;
    output Pointer<Variable> var;
  protected
    String err_str;
  algorithm
    var := match cref
      local
        Pointer<Variable> varPointer;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = varPointer)) then varPointer;
      else algorithm
        if ComponentRef.isTime(cref) then
          err_str := "there is no variable for the time cref, please treat differently.";
        else
          err_str := "because of wrong InstNode (not VAR_NODE). Please use NBVariable.getVarSafe if it should not fail here.";
        end if;
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref) + ", " + err_str});
      then fail();
    end match;
  end getVarPointer;

  function getVarName
    input Pointer<Variable> var_ptr;
    output ComponentRef name;
  protected
    Variable var;
  algorithm
    var := Pointer.access(var_ptr);
    name := var.name;
  end getVarName;

  function isState
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE())) then true;
      else false;
    end match;
  end isState;

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

  function isDAEResidual
    input Pointer<Variable> var;
    output Boolean b;
  algorithm
    b := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.DAE_RESIDUAL_VAR())) then true;
      else false;
    end match;
  end isDAEResidual;

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

  function setVariableKind
    input output Variable var;
    input BackendExtension.VariableKind varKind;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo backendinfo;
      case NFVariable.VARIABLE(backendinfo = backendinfo) algorithm
        backendinfo.varKind := varKind;
        var.backendinfo := backendinfo;
      then var;
    end match;
  end setVariableKind;

  function setVariableAttributes
    input output Variable var;
    input Option<BackendExtension.VariableAttributes> variableAttributes;
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
    input output ComponentRef cref    "old component reference to new component reference";
    output Pointer<Variable> var_ptr  "pointer to new variable";
  algorithm
    _ := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> state;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          state := BVariable.getVarPointer(cref);
          qual.name := DERIVATIVE_STR;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.nodeType(cref)));
          var := BVariable.fromCref(cref);
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.STATE_DER(state, NONE()));
          var_ptr := Pointer.create(var);
          cref := BackendDAE.lowerComponentReferenceInstNode(cref, var_ptr);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeDerVar;

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
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.nodeType(cref)));
          var := BVariable.fromCref(cref);
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.PREVIOUS(disc));
          var_ptr := Pointer.create(var);
          cref := BackendDAE.lowerComponentReferenceInstNode(cref, var_ptr);
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
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.nodeType(cref)));
          var := BVariable.fromCref(cref);
          // update the variable to be a seed and pass the pointer to the original variable
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.SEED_VAR(old_var_ptr));
          // create the new variable pointer and safe it to the component reference
          var_ptr := Pointer.create(var);
          cref := BackendDAE.lowerComponentReferenceInstNode(cref, var_ptr);
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
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.nodeType(cref)));
          var := BVariable.fromCref(cref);
          // update the variable to be a jac var and pass the pointer to the original variable
          // ToDo: tmps will get JAC_DIFF_VAR !
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.JAC_VAR());
          // create the new variable pointer and safe it to the component reference
          var_ptr := Pointer.create(var);
          cref := BackendDAE.lowerComponentReferenceInstNode(cref, var_ptr);
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
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.nodeType(cref)));
          var := BVariable.fromCref(cref);
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
    output Pointer<Variable> var_ptr  "pointer to new variable";
    output ComponentRef cref          "new component reference";
  protected
    InstNode node;
    Variable var;
  algorithm
    // create inst node with dummy variable pointer and create cref from it
    node := InstNode.VAR_NODE(RESIDUAL_STR + "_" + name + "_" + intString(uniqueIndex), Pointer.create(DUMMY_VARIABLE));
    // Type for residuals is always REAL() !
    cref := ComponentRef.CREF(node, {}, Type.REAL(), NFComponentRef.Origin.SCOPE, ComponentRef.EMPTY());
    // create variable and set its kind to dae_residual (change name?)
    var := BVariable.fromCref(cref);
    // update the variable to be a seed and pass the pointer to the original variable
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.DAE_RESIDUAL_VAR(uniqueIndex));
    // create the new variable pointer and safe it to the component reference
    var_ptr := Pointer.create(var);
    cref := BackendDAE.lowerComponentReferenceInstNode(cref, var_ptr);
  end makeResidualVar;

  // ==========================================================================
  //                        Other type wrappers
  //
  // ==========================================================================

  function checkExp
    input Expression exp;
    input checkFunc func;
    output Boolean b;
    partial function checkFunc
      input Pointer<Variable> var;
      output Boolean b;
    end checkFunc;
  algorithm
    b := match exp
      local
        ComponentRef cref;
      case Expression.CREF(cref = cref)
      then func(getVarPointer(cref));
      else false;
    end match;
  end checkExp;

  // ==========================================================================
  //                        Variable Array Stuff
  //    All variable arrays are pointer arrays to avoid duplicates
  // ==========================================================================
  uniontype VariablePointers
    record VARIABLE_POINTERS
      HashTableCrToInt.HashTable ht             "Hash table for cref->index";
      ExpandableArray<Pointer<Variable>> varArr "Array of variable pointers";
    end VARIABLE_POINTERS;

    function toString
      input VariablePointers variables;
      input output String str = "";
      input Boolean printEmpty = true;
    protected
      Pointer<Variable> var;
    algorithm
      if printEmpty or ExpandableArray.getNumberOfElements(variables.varArr) > 0 then
        str := ExpandableArray.toString(variables.varArr, str + " Variables", function Pointer.applyFold(func = function BVariable.toString()), false) + "\n";
      else
        str := "";
      end if;
    end toString;

    function map
      "Traverses all variables and applies a function to them.
       NOTE: Do not changes names with this, it will mess up the HashTable.
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
       NOTE: Do not changes names with this, it will mess up the HashTable.
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
      output VariablePointers variables;
    protected
      Integer arr_size, bucketSize;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      bucketSize :=  realInt(intReal(arr_size) * 1.4);
      variables := VARIABLE_POINTERS(HashTableCrToInt.empty(bucketSize), ExpandableArray.new(arr_size, Pointer.create(DUMMY_VARIABLE)));
    end empty;

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
      output VariablePointers variables;
    algorithm
      variables := empty(listLength(var_lst));
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
    end removeList;

    function add
      "Adds a variable pointer to the set, or updates it if it already exists."
      input Pointer<Variable> varPointer;
      input output VariablePointers variables;
    protected
      Variable var;
      Integer idx;
    algorithm
      var := Pointer.access(varPointer);
      if BaseHashTable.hasKey(var.name, variables.ht) then
        idx := BaseHashTable.get(var.name, variables.ht);
        ExpandableArray.set(idx, varPointer, variables.varArr);
      else
        (_, idx) := ExpandableArray.add(varPointer, variables.varArr);
      end if;
      variables.ht := BaseHashTable.add((var.name, idx), variables.ht);
    end add;

    function remove
      "Removes a variable pointer identified by its name from the set."
      input Pointer<Variable> var_ptr;
      input output VariablePointers variables "only an output for mapping";
    protected
      Variable var;
      Integer idx;
    algorithm
      var := Pointer.access(var_ptr);
      if BaseHashTable.hasKey(var.name, variables.ht) then
        idx := BaseHashTable.get(var.name, variables.ht);
        ExpandableArray.delete(idx, variables.varArr);
        BaseHashTable.delete(var.name, variables.ht);
      end if;
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
      variables.ht := BaseHashTable.add((var.name, idx), variables.ht);
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
      input ComponentRef cref;
      input VariablePointers variables;
      output Pointer<Variable> var_ptr;
    algorithm
      if BaseHashTable.hasKey(cref, variables.ht) then
        var_ptr := ExpandableArray.get(BaseHashTable.get(cref, variables.ht), variables.varArr);
      else
        if Flags.isSet(Flags.FAILTRACE) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
        end if;
        fail();
      end if;
    end getVarSafe;

    function getVarNames
      "returns a list of crefs representing the names of all variables"
      input VariablePointers variables;
      output list<ComponentRef> names;
    protected
      Pointer<list<ComponentRef>> acc = Pointer.create({});
    algorithm
      map(variables, function getVarNameTraverse(acc = acc));
      names := listReverse(Pointer.access(acc));
    end getVarNames;

    function size
      input VariablePointers variables;
      output Integer i;
    algorithm
      i := ExpandableArray.getNumberOfElements(variables.varArr);
    end size;

    function compress"O(n)
      Reorders the elements in order to remove all the gaps.
      Be careful: This changes the indices of the elements.
      Cannot use ExpandableArray.compress since it needs to
      update the HashTable."
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
          // udpate HashTable element
          BaseHashTable.update((getVarName(moved_var), i), vars.ht);
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
      variables := empty(size);
      for tpl in hash_lst loop
        (_, var_ptr) := tpl;
        variables := add(var_ptr, variables);
      end for;
    end sort;

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
      VariablePointers initials           "All initial unknowns (unknowns + states + previous)";
      VariablePointers auxiliaries        "Variables created by the backend known to be solved
                                          by given binding. E.g. $cse";
      VariablePointers aliasVars          "Variables removed due to alias removal";

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
          local
            VarData qualVarData;
          case qualVarData as VAR_DATA_SIM()  then VariablePointers.toString(varData.variables, "Simulation");
          case qualVarData as VAR_DATA_JAC()  then VariablePointers.toString(varData.variables, "Jacobian");
          case qualVarData as VAR_DATA_HES()  then VariablePointers.toString(varData.variables, "Hessian");
          case VAR_DATA_EMPTY()               then "Empty variable Data!\n";
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
          VarData qualVarData;
          String tmp = "";
          VariablePointers lambdaVars;
        case qualVarData as VAR_DATA_SIM() algorithm
          tmp := StringUtil.headline_2("Variable Data Simulation") + "\n" +
            VariablePointers.toString(varData.unknowns, "Unknown", false) +
            VariablePointers.toString(varData.states, "Local Known", false) +
            VariablePointers.toString(varData.knowns, "Global Known", false) +
            VariablePointers.toString(varData.auxiliaries, "Auxiliary", false) +
            VariablePointers.toString(varData.aliasVars, "Alias", false);
          if full then
            tmp := tmp + VariablePointers.toString(varData.states, "State", false) +
              VariablePointers.toString(varData.derivatives, "Derivative", false) +
              VariablePointers.toString(varData.algebraics, "Algebraic", false) +
              VariablePointers.toString(varData.discretes, "Discrete", false) +
              VariablePointers.toString(varData.previous, "Previous", false) +
              VariablePointers.toString(varData.parameters, "Parameter", false) +
              VariablePointers.toString(varData.constants, "Constant", false);
          end if;
        then tmp;

        case qualVarData as VAR_DATA_JAC() algorithm
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

        case qualVarData as VAR_DATA_HES() algorithm
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
        local
          VarData qual;
        case qual as VAR_DATA_SIM() algorithm qual.variables := variables; then qual;
        case qual as VAR_DATA_JAC() algorithm qual.variables := variables; then qual;
        case qual as VAR_DATA_HES() algorithm qual.variables := variables; then qual;
        else fail();
      end match;
    end setVariables;
  end VarData;

  // ==========================================================================
  //                      Protected utility functions
  // ==========================================================================
protected
  function getVarNameTraverse
    input output Variable var;
    input Pointer<list<ComponentRef>> acc;
  algorithm
    Pointer.update(acc, var.name :: Pointer.access(acc));
  end getVarNameTraverse;

  annotation(__OpenModelica_Interface="backend");
end NBVariable;
