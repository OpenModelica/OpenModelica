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
  import InstNode = NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Type = NFType;
  import Variable = NFVariable;
  import VariableKind = NFBackendExtension.VariableKind;

  // Backend Imports
  import BackendDAE = NBackendDAE;
  import BVariable = NBVariable;

  //Util Imports
  import Array;
  import BaseHashTable;
  import ExpandableArray;
  import Flags;
  import StringUtil;
  import Util;

  /* ==========================================================================
      We define two different arrays of variables.
      1: The actual array where all the variables are stored.
      2: Pointer array to the original variables to avoid duplicates.
  ========================================================================== */
public
  constant Variable DUMMY_VARIABLE = Variable.VARIABLE(ComponentRef.EMPTY(), Type.ANY(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PUBLIC, NFComponent.DEFAULT_ATTR,
    {}, NONE(), SCodeUtil.dummyInfo, NFBackendExtension.DUMMY_BACKEND_INFO);

  constant String DERIVATIVE_STR = "$DER";

  function toString
    input Variable var;
    output String str;
  algorithm
    str := VariableKind.toString(var.backendinfo.varKind) + " " + Variable.toString(var) + " " + InstNode.typeName(ComponentRef.node(var.name));
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
  algorithm
    var := match cref
      local
        Pointer<Variable> varPointer;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = varPointer)) then varPointer;
      else algorithm
        if Flags.isSet(Flags.FAILTRACE) then
          Error.addMessage(Error.INTERNAL_ERROR,{"NBVariable.Variables.getVarPointer failed for " + ComponentRef.toString(cref) + ", because of wrong InstNode (not VAR_NODE).
          Please use NBVariable.getVarSafe if it should not fail here."});
        end if;
      then fail();
    end match;
  end getVarPointer;

  function isState
    input Pointer<Variable> var;
    output Boolean isstate;
  algorithm
    isstate := match Pointer.access(var)
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE())) then true;
      else false;
    end match;
  end isState;

  uniontype VariablePointers
    record VARIABLE_POINTERS
      Integer bucketSize;
      array<list<CrefIndex>> crefIndices "HashTB, cref->indx";
      ExpandableArray<Pointer<Variable>> varArr "Array of variable pointers";
    end VARIABLE_POINTERS;

    function toString
      input VariablePointers variables;
      input output String str = "";
    protected
      Pointer<Variable> var;
    algorithm
       str := ExpandableArray.toString(variables.varArr, str + " VariablePointers", function Pointer.applyFold(func = function BVariable.toString()), false);
    end toString;

    function empty
      "Creates an empty VariablePointers using given size * 1.4."
      input Integer size = BaseHashTable.bigBucketSize;
      output VariablePointers variables;
    protected
      Integer arr_size, bucketSize;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      bucketSize :=  realInt(intReal(arr_size) * 1.4);
      variables := VARIABLE_POINTERS(bucketSize, arrayCreate(bucketSize, {}), ExpandableArray.new(arr_size, Pointer.create(DUMMY_VARIABLE)));
    end empty;

    function fromList
      "Creates VariablePointers from a VariablePointer list."
      input list<Pointer<Variable>> var_lst;
      output VariablePointers variables;
    algorithm
      variables := empty(listLength(var_lst));
      variables := addVars(var_lst, variables);
    end fromList;

    function addVars
      "Adds a list of variables to the Variables structure. If any variable already
      exists it's updated instead."
      input list<Pointer<Variable>> var_lst;
      input output VariablePointers variables;
    algorithm
      variables := List.fold(var_lst, function addVar(), variables);
    end addVars;

    function addVar
      "Adds a variable pointer to the set, or updates it if it already exists."
      input Pointer<Variable> varPointer;
      input output VariablePointers variables;
    protected
      Variable var;
      Integer hash_idx, arr_idx, new_idx;
      list<CrefIndex> indices;
    algorithm
      var := Pointer.access(varPointer);
      hash_idx := ComponentRef.hash(var.name, variables.bucketSize) + 1;
      indices := arrayGet(variables.crefIndices, hash_idx);

      try
        // If the variable already exists, overwrite it
        CREFINDEX(index = arr_idx) := List.getMemberOnTrue(var.name, indices, crefIndexEqualCref);
        ExpandableArray.set(arr_idx + 1, varPointer, variables.varArr);
      else
        // otherwise create new variable at the end of the array and expand if neccessary
        (_, new_idx) := ExpandableArray.add(varPointer, variables.varArr);
        arrayUpdate(variables.crefIndices, hash_idx, (CREFINDEX(var.name, new_idx - 1) :: indices));
      end try;
    end addVar;

    function removeVar
      "Removes a variable pointer identified by its name from the set."
      input Pointer<Variable> var_ptr;
      input output VariablePointers variables "only an output for mapping";
    protected
      Variable var;
      Integer hash_idx, arr_idx;
      list<CrefIndex> indices;
    algorithm
      var := Pointer.access(var_ptr);
      hash_idx := ComponentRef.hash(var.name, variables.bucketSize) + 1;
      indices := arrayGet(variables.crefIndices, hash_idx);

      try
        // If the variable exists, delete it
        CREFINDEX(index = arr_idx) := List.getMemberOnTrue(var.name, indices, crefIndexEqualCref);
        ExpandableArray.delete(arr_idx + 1, variables.varArr);
        indices := List.deleteMemberOnTrue(var.name, indices, crefIndexEqualCref);
        arrayUpdate(variables.crefIndices, hash_idx, indices);
      else
        // otherwise do nothing
      end try;
    end removeVar;

    function setVarAt
      "Sets a Variable pointer at a specific index in the VariablePointers."
      input VariablePointers variables;
      input Integer index;
      input Pointer<Variable> var;
    algorithm
      ExpandableArray.set(index, var, variables.varArr);
    end setVarAt;

    function getVarAt
      "Returns the variable pointer at given index. If there is none it fails."
      input VariablePointers variables;
      input Integer index;
      output Pointer<Variable> var;
    algorithm
      var := ExpandableArray.get(index, variables.varArr);
    end getVarAt;

    function getVarSafe
      "Use only for lowering purposes! Otherwise use the InstNode in the
      ComponentRef. Fails if the component ref cannot be found."
      input ComponentRef cref;
      input VariablePointers variables;
      output Pointer<Variable> var;
    protected
      Integer hash_idx, index;
      list<CrefIndex> cr_indices;
      ComponentRef cr;
    algorithm
      try
        hash_idx := ComponentRef.hash(cref, variables.bucketSize) + 1;
        cr_indices := variables.crefIndices[hash_idx];
        CREFINDEX(index = index) := List.getMemberOnTrue(cref, cr_indices, crefIndexEqualCref);
        var := getVarAt(variables, index + 1);
        NFVariable.VARIABLE(name = cr) := Pointer.access(var);
        true := ComponentRef.isEqual(cr, cref);
      else
        if Flags.isSet(Flags.FAILTRACE) then
          Error.addMessage(Error.INTERNAL_ERROR,{"NBVariable.Variables.getVarSafe failed for " + ComponentRef.toString(cref)});
        end if;
        fail();
      end try;
    end getVarSafe;
  end VariablePointers;

  uniontype CrefIndex
    "Component Reference Index"
    record CREFINDEX
      ComponentRef cref;
      Integer index;
    end CREFINDEX;
  end CrefIndex;

  uniontype VarData
    "All variable arrays are pointer subsets of an array of variables indicated
    by preceding comment. Used to traverse all variables of a special kind."

    record VAR_DATA_SIM
      "Only to be used for simulation systems."
      VariablePointers variables          "All variables";
      /* subset of full variable array */
      VariablePointers unknowns           "All state derivatives, algebraic variables,
                                          discrete variables";
      VariablePointers knowns             "Parameters, constants";
      VariablePointers auxiliaries        "Variables created by the backend known to be solved
                                          by given binding. E.g. $cse";
      VariablePointers aliasVars          "Variables removed due to alias removal";

      /* subset of unknowns */
      VariablePointers states             "States";
      VariablePointers derivatives        "State derivatives (der(x) -> $DER.x)";
      VariablePointers algebraics         "Algebraic variables";
      VariablePointers discretes          "Discrete variables";
      VariablePointers previous           "Previous discrete variables (pre(d) -> $PRE.d)";
      /* subset of knowns */
      VariablePointers parameters         "Parameters";
      VariablePointers constants          "Constants";
    end VAR_DATA_SIM;

    record VAR_DATA_JAC
      "Only to be used for Jacobians."
      VariablePointers variables                 "All jacobian variables";
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
    end VAR_DATA_JAC;

    record VAR_DATA_HESS
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
    end VAR_DATA_HESS;

    function toString
      input VarData varData;
      input Integer level = 0;
      output String str;
    algorithm
      str := if level == 0 then match varData
          local
            VarData qualVarData;
          case qualVarData as VAR_DATA_SIM() then VariablePointers.toString(varData.variables, "Simulation");
          case qualVarData as VAR_DATA_JAC() then VariablePointers.toString(varData.variables, "Jacobian");
          case qualVarData as VAR_DATA_HESS() then VariablePointers.toString(varData.variables, "Hessian");
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
            VariablePointers.toString(varData.unknowns, "Unknown") + "\n" +
            VariablePointers.toString(varData.knowns, "Known") + "\n" +
            VariablePointers.toString(varData.auxiliaries, "Auxiliary") + "\n" +
            VariablePointers.toString(varData.aliasVars, "Alias") + "\n";
          if full then
            tmp := tmp + VariablePointers.toString(varData.states, "State") + "\n" +
              VariablePointers.toString(varData.derivatives, "Derivative") + "\n" +
              VariablePointers.toString(varData.algebraics, "Algebraic") + "\n" +
              VariablePointers.toString(varData.discretes, "Discrete") + "\n" +
              VariablePointers.toString(varData.previous, "Previous") + "\n" +
              VariablePointers.toString(varData.parameters, "Parameter") + "\n" +
              VariablePointers.toString(varData.constants, "Constant") + "\n";
          end if;
        then tmp;

        case qualVarData as VAR_DATA_JAC() algorithm
          tmp := StringUtil.headline_2("Variable Data Jacobian") + "\n" +
            VariablePointers.toString(varData.unknowns, "Unknown") + "\n" +
            VariablePointers.toString(varData.knowns, "Known") + "\n" +
            VariablePointers.toString(varData.auxiliaries, "Auxiliary") + "\n" +
            VariablePointers.toString(varData.aliasVars, "Alias") + "\n";
          if full then
            tmp := tmp + VariablePointers.toString(varData.diffVars, "Differentiation") + "\n" +
              VariablePointers.toString(varData.dependencies, "Dependencies") + "\n" +
              VariablePointers.toString(varData.resultVars, "Result") + "\n" +
              VariablePointers.toString(varData.tmpVars, "Temporary") + "\n" +
              VariablePointers.toString(varData.seedVars, "Seed") + "\n";
          end if;
        then tmp;

        case qualVarData as VAR_DATA_HESS()algorithm
          tmp := StringUtil.headline_2("Variable Data Hessian") + "\n" +
            VariablePointers.toString(varData.unknowns, "Unknown") + "\n" +
            VariablePointers.toString(varData.knowns, "Known") + "\n" +
            VariablePointers.toString(varData.auxiliaries, "Auxiliary") + "\n" +
            VariablePointers.toString(varData.aliasVars, "Alias") + "\n";
          if full then
            tmp := tmp + VariablePointers.toString(varData.diffVars, "Differentiation") + "\n" +
              VariablePointers.toString(varData.dependencies, "Dependencies") + "\n" +
              VariablePointers.toString(varData.resultVars, "Result") + "\n" +
              VariablePointers.toString(varData.tmpVars, "Temporary") + "\n" +
              VariablePointers.toString(varData.seedVars, "First Seed") + "\n" +
              VariablePointers.toString(varData.seedVars2, "Second Seed") + "\n";
              if isSome(varData.lambdaVars) then
                SOME(lambdaVars) := varData.lambdaVars;
                tmp := tmp + VariablePointers.toString(lambdaVars, "Lagrangian Lambda") + "\n";
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
        case VAR_DATA_HESS(variables = tmp) then tmp;
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
        case qual as VAR_DATA_HESS() algorithm qual.variables := variables; then qual;
        else fail();
      end match;
    end setVariables;
  end VarData;

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
    input Option<DAE.VariableAttributes> variableAttributes;
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

protected
  function crefIndexEqualCref
    "Checks the component reference of a CrefIndex object and a reference cref
    for equality."
    input ComponentRef cr1;
    input CrefIndex crefIndex;
    output Boolean outMatch;
  protected
    ComponentRef cr2;
  algorithm
    CREFINDEX(cref = cr2) := crefIndex;
    outMatch := ComponentRef.isEqual(cr1, cr2);
  end crefIndexEqualCref;

  annotation(__OpenModelica_Interface="backend");
end NBVariable;
