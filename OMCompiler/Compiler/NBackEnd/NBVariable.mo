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
  import Binding = NFBinding;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import InstNode = NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Type = NFType;
  import Variable = NFVariable;
  import VariableKind = NFBackendExtension.VariableKind;

  // Backend Imports
  import BVariable = NBVariable;

  //Util Imports
  import Array;
  import BaseHashTable;
  import HashTable3;
  import HashTableCG;
  import StringUtil;
  import Util;

  /* ==========================================================================
      We define two different arrays of variables.
      1: The actual array where all the variables are stored.
      2: Pointer array to the original variables to avoid duplicates.
  ========================================================================== */
public


  constant Variable DUMMY_VARIABLE = Variable.VARIABLE(ComponentRef.EMPTY(), Type.ANY(),
    NFBinding.EMPTY_BINDING, NFPrefixes.Visibility.PROTECTED, NFComponent.DEFAULT_ATTR,
    {}, NONE(), SCodeUtil.dummyInfo, NFBackendExtension.DUMMY_BACKEND_INFO);


  function toString
    input Variable var;
    output String str;
  algorithm
    str := VariableKind.toString(var.backendinfo.varKind) + " " + Variable.toString(var);
  end toString;

  uniontype Variables
    record VARIABLES
      array<list<CrefIndex>> crefIndices "HashTB, cref->indx";
      VariableArray varArr "Array of variables";
      Integer bucketSize "bucket size";
      Integer numberOfVars "no. of vars";
    end VARIABLES;

    function toString
      input Variables variables;
      input output String str = "";
    algorithm
        str := StringUtil.headline_3(str + " Variables " + "(" + intString(variables.numberOfVars) + ")") + "\n";
        str := str + VariableArray.toString(variables.varArr);
    end toString;

    function empty
      "Creates an empty Variables object with minimal given size."
      input Integer size = BaseHashTable.defaultBucketSize;
      output Variables variables;
    protected
      Integer arr_size, bucketSize;
      VariableArray varArr;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      bucketSize :=  realInt(intReal(arr_size) * 1.4);
      varArr := VARIABLE_ARRAY(0, arrayCreate(arr_size, NONE()));
      variables := VARIABLES(arrayCreate(bucketSize, {}), varArr, bucketSize, 0);
    end empty;

    function fromList
      "Creates Variables from a Variable list."
      input list<Variable> var_lst;
      output Variables variables;
    algorithm
      variables := empty(listLength(var_lst));
      variables := addVars(var_lst, variables);
    end fromList;

    public function addVars
      "Adds a list of variables to the Variables structure. If any variable already
      exists it's updated instead."
      input list<Variable> var_lst;
      input output Variables variables;
    algorithm
      variables := List.fold(var_lst, addVar, variables);
    end addVars;

    function addVar
      "Adds a variable to the set, or updates it if it already exists."
      input Variable var;
      input output Variables variables;
    protected
      Integer hash_idx, arr_idx;
      list<CrefIndex> indices;
    algorithm
      hash_idx := ComponentRef.hash(var.name, variables.bucketSize) + 1;
      indices := arrayGet(variables.crefIndices, hash_idx);

      try
        // If the variable already exists, overwrite it
        CREFINDEX(index = arr_idx) := List.getMemberOnTrue(var.name, indices, crefIndexEqualCref);
        variables.varArr := VariableArray.setVarAt(variables.varArr, arr_idx + 1, var);
      else
        // otherwise create new variable at the end of the array and expand if neccessary
        variables.varArr := VariableArray.appendVar(variables.varArr, var);
        arrayUpdate(variables.crefIndices, hash_idx, (CREFINDEX(var.name, variables.numberOfVars) :: indices));
        variables.numberOfVars := variables.numberOfVars + 1;
      end try;
    end addVar;

    function setVarAt
      "Sets a Variable at a specific index in the VariableArray."
      input output Variables variables;
      input Integer index;
      input Variable var;
    algorithm
      variables.varArr := VariableArray.setVarAt(variables.varArr, index, var);
    end setVarAt;

    function getVarAt
      "Returns the variable at given index. If there is none it fails."
      input Variables variables;
      input Integer index;
      output Variable var;
    algorithm
      try
        SOME(var) := variables.varArr.varOptArr[index];
      else
        fail();
      end try;
    end getVarAt;

    public function getVar
      "Use only for lowering purposes! Otherwise use the InstNode in the
      ComponentRef."
      input ComponentRef cref;
      input Variables variables;
      output Variable var;
    protected
      Integer hash_idx, index;
      list<CrefIndex> cr_indices;
      ComponentRef cr;
    algorithm
      try
        hash_idx := ComponentRef.hash(cref, variables.bucketSize) + 1;
        cr_indices := variables.crefIndices[hash_idx];
        CREFINDEX(index = index) := List.getMemberOnTrue(cref, cr_indices, crefIndexEqualCref);
        var as NFVariable.VARIABLE(name = cr) := getVarAt(variables, index + 1);
        true := ComponentRef.isEqual(cr, cref);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{"NBVariable.Variables.getVar failed for " + ComponentRef.toString(cref)});
      end try;
    end getVar;

    function updateInstNode
      input output ComponentRef cref;
      input Variables variables;
    algorithm
      cref := match cref
        local
          ComponentRef qualCref;

        case qualCref as ComponentRef.CREF()
          algorithm
            qualCref.node := InstNode.VAR_NODE(Pointer.create(getVar(cref, variables)));
        then qualCref;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{"NBVariable.Variables.setVarPointer failed for " + ComponentRef.toString(cref)});
        then fail();

      end match;
    end updateInstNode;
  end Variables;

  uniontype VariableArray
    "array of variables are expandable, to amortize the cost of adding
    equations in a more efficient manner"
    record VARIABLE_ARRAY
      Integer numberOfElements "no. elements";
      array<Option<Variable>> varOptArr;
    end VARIABLE_ARRAY;

    function toString
      input VariableArray varArr;
      output String str = "";
    protected
      Variable var;
    algorithm
      for i in 1:arrayLength(varArr.varOptArr) loop
        if isSome(varArr.varOptArr[i]) then
          SOME(var) := varArr.varOptArr[i];
          str := str + "(" + intString(i) + ")\t" + BVariable.toString(var) + "\n";
        end if;
      end for;
    end toString;

    function setVarAt
      "Sets a Variable at a specific index in the VariableArray."
      input output VariableArray varArr;
      input Integer index;
      input Variable var;
    algorithm
      true := index <= varArr.numberOfElements;
      arrayUpdate(varArr.varOptArr, index, SOME(var));
    end setVarAt;

    function appendVar
    "author: PA
      Adds a variable last to the VariableArray, increasing array size
      if no space left by factor 1.4"
      input output VariableArray varArr;
      input Variable var;
    protected
      array<Option<Variable>> arr;
    algorithm
      varArr.numberOfElements := varArr.numberOfElements + 1;
      varArr.varOptArr := Array.expandOnDemand(varArr.numberOfElements, varArr.varOptArr, 1.4, NONE());
      arrayUpdate(varArr.varOptArr, varArr.numberOfElements, SOME(var));
    end appendVar;
  end VariableArray;

  uniontype VariablePointers
    record VARIABLE_POINTERS
      array<list<CrefIndex>> crefIndices "HashTB, cref->indx";
      VariablePointerArray varArr "Array of variable pointers";
      Integer bucketSize "bucket size";
      Integer numberOfVars "no. of variable pointers";
    end VARIABLE_POINTERS;

    function toString
      input VariablePointers variables;
      input output String str = "";
    algorithm
        str := StringUtil.headline_4(str + " VariablePointers " + "(" + intString(variables.numberOfVars) + ")") + "\n";
        str := str + VariablePointerArray.toString(variables.varArr);
    end toString;

    function empty
      "Creates an empty VariablePointers using given size * 1.4."
      input Integer size = BaseHashTable.bigBucketSize;
      output VariablePointers variables;
    protected
      Integer arr_size, bucketSize;
      VariablePointerArray varArr;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      bucketSize :=  realInt(intReal(arr_size) * 1.4);
      varArr := VARIABLE_POINTER_ARRAY(0, arrayCreate(arr_size, NONE()));
      variables := VARIABLE_POINTERS(arrayCreate(bucketSize, {}), varArr, bucketSize, 0);
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
      variables := List.fold(var_lst, addVar, variables);
    end addVars;

    function addVar
      "Adds a variable pointer to the set, or updates it if it already exists."
      input Pointer<Variable> varPointer;
      input output VariablePointers variables;
    protected
      Variable var;
      Integer hash_idx, arr_idx;
      list<CrefIndex> indices;
    algorithm
      var := Pointer.access(varPointer);
      hash_idx := ComponentRef.hash(var.name, variables.bucketSize) + 1;
      indices := arrayGet(variables.crefIndices, hash_idx);

      try
        // If the variable already exists, overwrite it
        CREFINDEX(index = arr_idx) := List.getMemberOnTrue(var.name, indices, crefIndexEqualCref);
        variables.varArr := VariablePointerArray.setVarAt(variables.varArr, arr_idx + 1, varPointer);
      else
        // otherwise create new variable at the end of the array and expand if neccessary
        variables.varArr := VariablePointerArray.appendVar(variables.varArr, varPointer);
        arrayUpdate(variables.crefIndices, hash_idx, (CREFINDEX(var.name, variables.numberOfVars) :: indices));
        variables.numberOfVars := variables.numberOfVars + 1;
      end try;
    end addVar;

    function setVarAt
      "Sets a Variable pointer at a specific index in the VariablePointerArray."
      input output VariablePointers variables;
      input Integer index;
      input Pointer<Variable> var;
    algorithm
      variables.varArr := VariablePointerArray.setVarAt(variables.varArr, index, var);
    end setVarAt;

    function getVarAt
      "Returns the variable pointer at given index. If there is none it fails."
      input VariablePointers variables;
      input Integer index;
      output Pointer<Variable> var;
    algorithm
      try
        SOME(var) := variables.varArr.varOptArr[index];
      else
        fail();
      end try;
    end getVarAt;
  end VariablePointers;

  uniontype VariablePointerArray
    record VARIABLE_POINTER_ARRAY
      Integer numberOfElements "no. elements";
      array<Option<Pointer<Variable>>> varOptArr;
    end VARIABLE_POINTER_ARRAY;

    function toString
      input VariablePointerArray varArr;
      output String str = "";
    protected
      Pointer<Variable> var;
    algorithm
      for i in 1:arrayLength(varArr.varOptArr) loop
        if isSome(varArr.varOptArr[i]) then
          SOME(var) := varArr.varOptArr[i];
          str := str + "(" + intString(i) + ")\t" + BVariable.toString(Pointer.access(var)) + "\n";
        end if;
      end for;
    end toString;

    function setVarAt
      "Sets a VariablePointer at a specific index in the VariablePointerArray."
      input output VariablePointerArray varArr;
      input Integer index;
      input Pointer<Variable> var;
    algorithm
      true := index <= varArr.numberOfElements;
      arrayUpdate(varArr.varOptArr, index, SOME(var));
    end setVarAt;

    function appendVar
      "Adds a variable pointer last to the VariablePointerArray, increasing array
      size if no space left by factor 1.4"
      input output VariablePointerArray varArr;
      input Pointer<Variable> var;
    protected
      array<Option<Pointer<Variable>>> arr;
    algorithm
      varArr.numberOfElements := varArr.numberOfElements + 1;
      varArr.varOptArr := Array.expandOnDemand(varArr.numberOfElements, varArr.varOptArr, 1.4, NONE());
      arrayUpdate(varArr.varOptArr, varArr.numberOfElements, SOME(var));
    end appendVar;
  end VariablePointerArray;

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
      Variables variables                 "All variables";
      /* subset of full variable array */
      VariablePointers unknowns           "All state derivatives, algebraic variables,
                                          discrete variables";
      VariablePointers knowns             "Parameters, constants";
      VariablePointers auxiliaries        "Variables created by the backend known to be solved
                                          by given binding. E.g. $cse";
      VariablePointers aliasVars          "Variables removed due to alias removal";

      StateOrder stateOrder               "StateOrder dy/dt = x";
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
      Variables variables                 "All jacobian variables";
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
      Variables variables                 "All hessian variables";
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
      /* ToDo! Add StateOrder */
      input VarData varData;
      input Integer level = 0;
      output String str;
    algorithm
      str := if level == 0 then match varData
          local
            VarData qualVarData;
          case qualVarData as VAR_DATA_SIM() then Variables.toString(varData.variables, "Simulation");
          case qualVarData as VAR_DATA_JAC() then Variables.toString(varData.variables, "Jacobian");
          case qualVarData as VAR_DATA_HESS() then Variables.toString(varData.variables, "Hessian");
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
      output Variables variables;
    algorithm
      variables := match varData
        local
          Variables tmp;
        case VAR_DATA_SIM(variables = tmp) then tmp;
        case VAR_DATA_JAC(variables = tmp) then tmp;
        case VAR_DATA_HESS(variables = tmp) then tmp;
        else fail();
      end match;
    end getVariables;
  end VarData;

  uniontype StateOrder
    record STATE_ORDER
      HashTableCG.HashTable hashTable "x -> dx";
      HashTable3.HashTable invHashTable "dx -> {x,y,z}";
    end STATE_ORDER;
    record NO_STATE_ORDER
      "Index reduction disabled; don't need big hashtables"
    end NO_STATE_ORDER;
  end StateOrder;

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
