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
encapsulated uniontype NBStrongComponent
"file:        NBStrongComponent.mo
 package:     NBStrongComponent
 description: This file contains the data-types used save the strong Component
              data after causalization.
"
protected
  // selfimport
  import StrongComponent = NBStrongComponent;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import Adjacency = NBAdjacency;
  import BackendDAE = NBackendDAE;
  import Causalize = NBCausalize;
  import BVariable = NBVariable;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EquationAttributes, Iterator};
  import NBJacobian.JacobianType;
  import Matching = NBMatching;
  import Solve = NBSolve;
  import Sorting = NBSorting;
  import BSystem = NBSystem;
  import NBSystem.{System, SystemType};
  import Tearing = NBTearing;
  import NBVariable.{VariablePointer, VariablePointers};

  // Util imports
  import Pointer;
  import Slice = NBSlice;
  import StringUtil;
  import UnorderedMap;
  import UnorderedSet;

public
  uniontype AliasInfo
    record ALIAS_INFO
      SystemType systemType     "The partition type";
      Integer partitionIndex    "the partition index";
      Integer componentIndex    "The index in that strong component array";
    end ALIAS_INFO;

    function toString
      input AliasInfo info;
      output String str = System.systemTypeString(info.systemType) + "[" + intString(info.partitionIndex) + " | " + intString(info.componentIndex) + "]";
    end toString;

    function hash
      input AliasInfo info;
      input Integer mod;
      output Integer i = intMod(System.systemTypeInteger(info.systemType) + info.partitionIndex*13 + info.componentIndex*31, mod);
    end hash;

    function isEqual
      input AliasInfo info1;
      input AliasInfo info2;
      output Boolean b = (info1.componentIndex == info2.componentIndex) and (info1.partitionIndex == info2.partitionIndex) and (info1.systemType == info2.systemType);
    end isEqual;
  end AliasInfo;

  record SINGLE_EQUATION
    Pointer<Variable> var;
    Pointer<Equation> eqn;
    Solve.Status status;
  end SINGLE_EQUATION;

  record SINGLE_ARRAY
    Pointer<Variable> var;
    Pointer<Equation> eqn;
    Solve.Status status;
  end SINGLE_ARRAY;

  record SINGLE_ALGORITHM
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
    Solve.Status status;
  end SINGLE_ALGORITHM;

  record SINGLE_RECORD_EQUATION
    Pointer<Variable> var;
    Pointer<Equation> eqn;
    Solve.Status status;
  end SINGLE_RECORD_EQUATION;

  record SINGLE_WHEN_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
    Solve.Status status;
  end SINGLE_WHEN_EQUATION;

  record SINGLE_IF_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
    Solve.Status status;
  end SINGLE_IF_EQUATION;

  record SLICED_EQUATION
    "zero based indices"
    ComponentRef var_cref       "cref to solve for";
    Slice<VariablePointer> var  "sliced variable";
    Slice<EquationPointer> eqn  "sliced equation";
    Solve.Status status;
  end SLICED_EQUATION;

  record ENTWINED_EQUATION
    "intermediate type, cannot be passed to SimCode! Will be resolved by the Solve Module."
    list<StrongComponent> entwined_slices                     "has to be SLICED_EQUATION()";
    list<tuple<Pointer<Equation>, Integer>> entwined_tpl_lst  "equation with scalar idx (0 based) - fallback scalarization";
  end ENTWINED_EQUATION;

  record ALGEBRAIC_LOOP
     "intermediate type, cannot be passed to SimCode! Will be resolved by the Tearing Module."
    list<Pointer<Variable>> vars;
    list<Pointer<Equation>> eqns;
    Option<BackendDAE> jac;
    Boolean mixed         "true for systems that have discrete variables";
    Solve.Status status;
  end ALGEBRAIC_LOOP;

  record TORN_LOOP
    Integer idx;
    Tearing strict;
    Option<Tearing> casual;
    Boolean linear;
    Boolean mixed "true for systems that have discrete variables";
    Solve.Status status;
  end TORN_LOOP;

  record ALIAS
    "Only to be used by Solve! Represents equal systems in ODE<->INIT<->DAE"
    AliasInfo aliasInfo       "The strong component array and index it refers to";
    StrongComponent original  "The original strong component for analysis";
  end ALIAS;

  function toString
    input StrongComponent comp;
    input Integer index = -1          "negative indices will not be printed";
    output String str;
  protected
    String indexStr = if index > 0 then " " + intString(index) else "";
  algorithm
    str := match comp
      local
        Tearing casual;
        Integer len;

      case SINGLE_EQUATION() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Equation (status = " + Solve.statusString(comp.status) + ")");
        str := str + "### Variable:\n" + Variable.toString(Pointer.access(comp.var), "\t") + "\n";
        str := str + "### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SLICED_EQUATION() algorithm
        len := listLength(comp.eqn.indices);
        str := if index == -2 then "" else StringUtil.headline_3("BLOCK" + indexStr + ": Sliced Equation (status = " + Solve.statusString(comp.status) + ")");
        str := str + "### Variable:\n\t" + ComponentRef.toString(comp.var_cref) + "\n";
        str := str + "### Equation:\n" + Slice.toString(comp.eqn, function Equation.pointerToString(str = "\t")) + "\n";
      then str;

      case ENTWINED_EQUATION() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Entwined Equation (status = Solve.UNPROCESSED)");
        str := str + List.toString(comp.entwined_slices, function toString(index = -2), "", "", "", "");
      then str;

      case SINGLE_ARRAY() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Array (status = " + Solve.statusString(comp.status) + ")");
        str := str + "### Variable:\n" + Variable.toString(Pointer.access(comp.var), "\t") + "\n";
        str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_ALGORITHM() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Algorithm (status = " + Solve.statusString(comp.status) + ")");
        str := str + "### Variables:\n";
        for var in comp.vars loop
          str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
        end for;
        str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_RECORD_EQUATION() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Record Equation (status = " + Solve.statusString(comp.status) + ")");
        str := str + "### Variable:\n" + Variable.toString(Pointer.access(comp.var), "\t") + "\n";
        str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_WHEN_EQUATION() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Single When-Equation (status = " + Solve.statusString(comp.status) + ")");
        str := str + "### Variables:\n";
        for var in comp.vars loop
          str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
        end for;
        str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_IF_EQUATION() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Single If-Equation (status = " + Solve.statusString(comp.status) + ")");
        str := str + "### Variables:\n";
        for var in comp.vars loop
          str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
        end for;
        str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case ALGEBRAIC_LOOP() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Algebraic Loop (Mixed = " + boolString(comp.mixed) + ")");
        str := str + "### Variables:\n";
        for var in comp.vars loop
          str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
        end for;
        str := str + "\n### Equations:\n";
        for eqn in comp.eqns loop
          str := str  + Equation.toString(Pointer.access(eqn), "\t") + "\n";
        end for;
      then str;

      case TORN_LOOP() algorithm
        str := StringUtil.headline_3("BLOCK" + indexStr + ": Torn Algebraic Loop (Linear = " + boolString(comp.linear) + ", Mixed = " + boolString(comp.mixed) + ")");
        str := str + Tearing.toString(comp.strict, "Strict Tearing Set");
        if isSome(comp.casual) then
          SOME(casual) := comp.casual;
          str := str + Tearing.toString(casual, "Casual Tearing Set");
        end if;
      then str;

      case ALIAS() algorithm
        str := "--- Alias of " + AliasInfo.toString(comp.aliasInfo) + " ---\n" + toString(comp.original, index);
      then str;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end toString;

  function hash
    "only hashes basic types, isEqual is used to differ between sliced/entwined loops"
    input StrongComponent comp;
    input Integer mod;
    output Integer i;
  algorithm
    i := match comp
      case SINGLE_EQUATION()        then intMod(BVariable.hash(comp.var, mod) + Equation.hash(comp.eqn, mod), mod);
      case SINGLE_ARRAY()           then intMod(BVariable.hash(comp.var, mod) + Equation.hash(comp.eqn, mod), mod);
      case SINGLE_ALGORITHM()       then intMod(Equation.hash(comp.eqn, mod), mod);
      case SINGLE_RECORD_EQUATION() then intMod(BVariable.hash(comp.var, mod) + Equation.hash(comp.eqn, mod), mod);
      case SINGLE_WHEN_EQUATION()   then intMod(sum(BVariable.hash(var, mod) for var in comp.vars) + Equation.hash(comp.eqn, mod), mod);
      case SINGLE_IF_EQUATION()     then intMod(sum(BVariable.hash(var, mod) for var in comp.vars) + Equation.hash(comp.eqn, mod), mod);
      case SLICED_EQUATION()        then intMod(ComponentRef.hash(comp.var_cref, mod) + Equation.hash(Slice.getT(comp.eqn), mod), mod);
      case ENTWINED_EQUATION()      then intMod(sum(hash(sub_comp, mod) for sub_comp in comp.entwined_slices), mod);
      case ALGEBRAIC_LOOP()         then intMod(sum(BVariable.hash(var, mod) for var in comp.vars) + sum(Equation.hash(eqn, mod) for eqn in comp.eqns), mod);
      case TORN_LOOP()              then intMod(Tearing.hash(comp.strict, mod), mod);
      case ALIAS()                  then AliasInfo.hash(comp.aliasInfo, mod);
    end match;
  end hash;

  function isEqual
    input StrongComponent comp1;
    input StrongComponent comp2;
    output Boolean b;
  algorithm
    b := match(comp1, comp2)
      case (SINGLE_EQUATION(), SINGLE_EQUATION())                 then BVariable.equalName(comp1.var, comp2.var) and Equation.equalName(comp1.eqn, comp2.eqn);
      case (SINGLE_ARRAY(), SINGLE_ARRAY())                       then BVariable.equalName(comp1.var, comp2.var) and Equation.equalName(comp1.eqn, comp2.eqn);
      case (SINGLE_ALGORITHM(), SINGLE_ALGORITHM())               then Equation.equalName(comp1.eqn, comp2.eqn);
      case (SINGLE_RECORD_EQUATION(), SINGLE_RECORD_EQUATION())   then BVariable.equalName(comp1.var, comp2.var) and Equation.equalName(comp1.eqn, comp2.eqn);
      case (SINGLE_WHEN_EQUATION(), SINGLE_WHEN_EQUATION())       then Equation.equalName(comp1.eqn, comp2.eqn) and List.isEqualOnTrue(comp1.vars, comp2.vars, BVariable.equalName);
      case (SINGLE_IF_EQUATION(), SINGLE_IF_EQUATION())           then Equation.equalName(comp1.eqn, comp2.eqn) and List.isEqualOnTrue(comp1.vars, comp2.vars, BVariable.equalName);
      case (SLICED_EQUATION(), SLICED_EQUATION())                 then ComponentRef.isEqual(comp1.var_cref, comp2.var_cref) and Slice.isEqual(comp1.eqn, comp2.eqn, Equation.equalName);
      case (ENTWINED_EQUATION(), ENTWINED_EQUATION())             then List.isEqualOnTrue(comp1.entwined_slices, comp2.entwined_slices, isEqual);
      case (ALGEBRAIC_LOOP(), ALGEBRAIC_LOOP())                   then List.isEqualOnTrue(comp1.vars, comp2.vars, BVariable.equalName) and List.isEqualOnTrue(comp1.eqns, comp2.eqns, Equation.equalName);
      case (TORN_LOOP(), TORN_LOOP())                             then Tearing.isEqual(comp1.strict, comp2.strict);
      case (ALIAS(), ALIAS())                                     then AliasInfo.isEqual(comp1.aliasInfo, comp2.aliasInfo);
      else false;
    end match;
  end isEqual;

  function create
    input list<Integer> comp_indices;
    input Matching matching;
    input VariablePointers vars;
    input EquationPointers eqns;
    output StrongComponent comp;
  algorithm
    comp := match matching
      case Causalize.SCALAR_MATCHING() algorithm
      then createScalar(comp_indices, matching.eqn_to_var, vars, eqns);

      case Causalize.ARRAY_MATCHING() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array strong components are not yet supported."});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end create;

  function createPseudo
    input list<Integer> comp_indices;
    input array<Integer> eqn_to_var;
    input VariablePointers vars;
    input EquationPointers eqns;
    input Adjacency.Mapping mapping;
    input Adjacency.CausalizeModes modes;
    input Sorting.PseudoBucket bucket;
    output Option<StrongComponent> comp;
  algorithm
    comp := match comp_indices
      local
        Integer i, mode;
        Sorting.PseudoBucketValue val;
        Sorting.PseudoBucketKey key;
        ComponentRef cref_to_solve;
        list<Integer> eqn_scal_indices;
        list<tuple<Pointer<Equation>, Integer>> entwined_tpl_lst;
        list<StrongComponent> entwined = {};

      case {i} guard(Adjacency.CausalizeModes.contains(i, modes)) algorithm
        if bucket.marks[i] then
          // has already been created
          comp := NONE();
        else
          // get mode and bucket
          mode  := Adjacency.CausalizeModes.get(i, eqn_to_var[i], modes);
          val   := Sorting.PseudoBucket.get(i, mapping.eqn_StA[i], mode, bucket);

          comp := match val
            case Sorting.PSEUDO_BUCKET_SINGLE()
            then SOME(createPseudoSlice(mapping.eqn_StA[i], val.cref_to_solve, val.eqn_scal_indices, eqns, mapping, bucket));

            case Sorting.PSEUDO_BUCKET_ENTWINED() algorithm
              for tpl in val.entwined_lst loop
                // has to be single because nested entwining not allowed (already flattened)
                (key, Sorting.PSEUDO_BUCKET_SINGLE(cref_to_solve, eqn_scal_indices, _, _)) := tpl;
                entwined := createPseudoSlice(key.eqn_arr_idx, cref_to_solve, eqn_scal_indices, eqns, mapping, bucket) :: entwined;
              end for;
              entwined_tpl_lst := createPseudoEntwinedIndices(val.entwined_arr, eqns, mapping);
            then SOME(ENTWINED_EQUATION(entwined, entwined_tpl_lst));

            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
            then fail();
          end match;
        end if;
      then comp;

      // if it is no array structure just use scalar
      else SOME(createPseudoScalar(comp_indices, eqn_to_var, mapping, vars, eqns));
    end match;
  end createPseudo;

  function createPseudoSlice
    input Integer eqn_arr_idx;
    input ComponentRef cref_to_solve;
    input list<Integer> eqn_scal_indices;
    input EquationPointers eqns;
    input Adjacency.Mapping mapping;
    input Sorting.PseudoBucket bucket;
    output StrongComponent slice;
  protected
    Pointer<Equation> eqn_ptr;
    Integer first_eqn;
  algorithm
    // get and save sliced equation
    eqn_ptr := EquationPointers.getEqnAt(eqns, eqn_arr_idx);
    (first_eqn, _) := mapping.eqn_AtS[eqn_arr_idx];

    // mark all scalar indices
    for scal_idx in eqn_scal_indices loop
      arrayUpdate(bucket.marks, scal_idx, true);
    end for;

    // variable slice necessary? if yes fill it!
    slice := SLICED_EQUATION(
      var_cref    = cref_to_solve,
      var         = Slice.SLICE(BVariable.getVarPointer(cref_to_solve), {}),
      eqn         = Slice.SLICE(eqn_ptr, list(idx - first_eqn for idx in listReverse(eqn_scal_indices))),
      status      = NBSolve.Status.UNPROCESSED
    );
  end createPseudoSlice;

  function createAlias
    input SystemType systemType;
    input Integer partitionIndex;
    input Pointer<Integer> index_ptr;
    input StrongComponent orig_comp;
    output StrongComponent alias_comp;
  algorithm
    alias_comp := ALIAS(ALIAS_INFO(systemType, partitionIndex, Pointer.access(index_ptr)), orig_comp);
    Pointer.update(index_ptr, Pointer.access(index_ptr) + 1);
  end createAlias;

  function createPseudoEntwinedIndices
    input array<list<Integer>> entwined_indices;
    input EquationPointers eqns;
    input Adjacency.Mapping mapping;
    output list<tuple<Pointer<Equation>, Integer>> flat_tpl_indices = {};
  protected
    Integer arr_idx, first_idx;
    array<Integer> eqn_StA        "safe access with iterated integer (void pointer)";
  algorithm
    for tmp in entwined_indices loop
      for scal_idx in tmp loop
        eqn_StA := mapping.eqn_StA;
        arr_idx := eqn_StA[scal_idx];
        (first_idx, _) := mapping.eqn_AtS[arr_idx];
        flat_tpl_indices := (EquationPointers.getEqnAt(eqns, arr_idx), scal_idx-first_idx) :: flat_tpl_indices;
      end for;
    end for;
    flat_tpl_indices := listReverse(flat_tpl_indices);
  end createPseudoEntwinedIndices;

  function makeDAEModeResidualTraverse
    " update later to do both inner and residual equations "
    input Pointer<Equation> eq_ptr;
    input Pointer<list<StrongComponent>> acc;
  protected
    StrongComponent comp;
  algorithm
    comp := match Pointer.access(eq_ptr)
      local
        Pointer<Variable> residualVar;

      case Equation.SCALAR_EQUATION(attr = EquationAttributes.EQUATION_ATTRIBUTES(residualVar = SOME(residualVar)))
      then SINGLE_EQUATION(residualVar, eq_ptr, NBSolve.Status.UNPROCESSED);

      case Equation.ARRAY_EQUATION(attr = EquationAttributes.EQUATION_ATTRIBUTES(residualVar = SOME(residualVar)))
      then SINGLE_ARRAY(residualVar, eq_ptr, NBSolve.Status.UNPROCESSED);

      // maybe check for type SINGLE // ARRAY ?
      case Equation.SIMPLE_EQUATION(attr = EquationAttributes.EQUATION_ATTRIBUTES(residualVar = SOME(residualVar)))
      then SINGLE_EQUATION(residualVar, eq_ptr, NBSolve.Status.UNPROCESSED);

      /* are other residuals possible? */

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;

    Pointer.update(acc, comp :: Pointer.access(acc));
  end makeDAEModeResidualTraverse;

  function fromSolvedEquation
    "creates a strong component assuming the equation is already solved
    todo: if and when equations"
    input Pointer<Equation> eqn;
    output StrongComponent comp;
  algorithm
    comp := match Pointer.access(eqn)
      case Equation.SCALAR_EQUATION() then SINGLE_EQUATION(BVariable.getVarPointer(Expression.toCref(Equation.getLHS(Pointer.access(eqn)))), eqn, NBSolve.Status.EXPLICIT);
      case Equation.ARRAY_EQUATION()  then SINGLE_ARRAY(BVariable.getVarPointer(Expression.toCref(Equation.getLHS(Pointer.access(eqn)))), eqn, NBSolve.Status.EXPLICIT);
      case Equation.RECORD_EQUATION() then SINGLE_RECORD_EQUATION(BVariable.getVarPointer(Expression.toCref(Equation.getLHS(Pointer.access(eqn)))), eqn, NBSolve.Status.EXPLICIT);
      case Equation.FOR_EQUATION()    then SLICED_EQUATION(ComponentRef.EMPTY(), Slice.SLICE(Pointer.create(NBVariable.DUMMY_VARIABLE), {}), Slice.SLICE(eqn, {}), NBSolve.Status.EXPLICIT);
      // ToDo: the other types
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end fromSolvedEquation;

  function toSolvedEquation
    "creates a solved equation for an explicitely solved strong component.
    fails if it is not solved explicitely."
    input StrongComponent comp;
    output Pointer<Equation> eqn;
  algorithm
    eqn := match comp
      case SINGLE_EQUATION(status = NBSolve.Status.EXPLICIT)          then comp.eqn;
      case SINGLE_ARRAY(status = NBSolve.Status.EXPLICIT)             then comp.eqn;
      case SINGLE_RECORD_EQUATION(status = NBSolve.Status.EXPLICIT)   then comp.eqn;
      case SINGLE_IF_EQUATION(status = NBSolve.Status.EXPLICIT)       then comp.eqn;
      case SINGLE_WHEN_EQUATION(status = NBSolve.Status.EXPLICIT)     then comp.eqn;
      case SLICED_EQUATION(status = NBSolve.Status.EXPLICIT)          then Slice.getT(comp.eqn);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong component could not be
        solved explicitely:\n" + StrongComponent.toString(comp)});
      then fail();
    end match;
  end toSolvedEquation;

  function collectCrefs
    "Collects dependent crefs in current comp and saves them in the
     unordered map. Saves both directions."
    input StrongComponent comp                                "strong component to be analyzed";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map  "unordered map to save the dependencies";
    input UnorderedSet<ComponentRef> set                      "unordered set of array crefs to check for relevance";
    input Boolean pseudo                                      "true if arrays are unscalarized";
    input JacobianType jacType                                "sets the context";
  algorithm
    _ := match comp
      local
        ComponentRef cref;
        list<ComponentRef> dependencies = {}, loop_vars = {}, tmp;
        list<tuple<ComponentRef, list<ComponentRef>>> scalarized_dependencies;
        Tearing strict;
        Equation eqn;
        Iterator iter;
        list<ComponentRef> names;
        list<Expression> ranges;

      case SINGLE_EQUATION() algorithm
        dependencies := Equation.collectCrefs(Pointer.access(comp.eqn), function Slice.getDependentCrefCausalized(set = set));
        updateDependencyMap(BVariable.getVarName(comp.var), dependencies, map, jacType);
      then ();

      // sliced for equations - create all the single entries
      case SLICED_EQUATION() guard(Equation.isForEquation(Slice.getT(comp.eqn))) algorithm
        eqn as Equation.FOR_EQUATION(iter = iter) := Pointer.access(Slice.getT(comp.eqn));
        dependencies := Equation.collectCrefs(eqn, function Slice.getDependentCrefCausalized(set = set));
        scalarized_dependencies := Slice.getDependentCrefsPseudoForCausalized(comp.var_cref, dependencies, map, iter);
        for tpl in scalarized_dependencies loop
          (cref, dependencies) := tpl;
          updateDependencyMap(cref, dependencies, map, jacType);
        end for;
      then ();

      // sliced regular equation. ToDo: what if slice is array?
      case SLICED_EQUATION() algorithm
        eqn := Pointer.access(Slice.getT(comp.eqn));
        dependencies := Equation.collectCrefs(eqn, function Slice.getDependentCrefCausalized(set = set));
        updateDependencyMap(comp.var_cref, dependencies, map, jacType);
      then ();

      case SINGLE_ARRAY() algorithm
        dependencies := Equation.collectCrefs(Pointer.access(comp.eqn), function Slice.getDependentCrefCausalized(set = set));
        updateDependencyMap(BVariable.getVarName(comp.var), dependencies, map, jacType);
      then ();

      case TORN_LOOP(strict = strict) algorithm
        // collect iteration loop vars
        for var in strict.iteration_vars loop
          loop_vars := BVariable.getVarName(var) :: loop_vars;
        end for;

        // traverse residual equations and collect dependencies
        for slice in strict.residual_eqns loop
          // ToDo: does this work properly for arrays?
          tmp := Equation.collectCrefs(Pointer.access(Slice.getT(slice)), function Slice.getDependentCrefCausalized(set = set));
          dependencies := listAppend(tmp, dependencies);
        end for;

        // traverse inner equations and collect loop vars and dependencies
        for i in 1:arrayLength(strict.innerEquations) loop
          // collect inner equation dependencies
          tmp := Equation.collectCrefs(Pointer.access(strict.innerEquations[i].eqn), function Slice.getDependentCrefCausalized(set = set));
          dependencies := listAppend(tmp, dependencies);

          // collect inner loop variables
          loop_vars := BVariable.getVarName(strict.innerEquations[i].var) :: loop_vars;
        end for;

        // add all dependencies
        for cref in loop_vars loop
          updateDependencyMap(cref, dependencies, map, jacType);
        end for;
      then ();

      case ALIAS() algorithm
        collectCrefs(comp.original, map, set, pseudo, jacType);
      then ();

      /* ToDo add the others and let else case fail! */

      else ();
    end match;
  end collectCrefs;

  function addLoopJacobian
    input output StrongComponent comp;
    input Option<BackendDAE> jac;
  algorithm
    comp := match comp
      local
        Tearing strict;

      case ALGEBRAIC_LOOP() algorithm
        comp.jac := jac;
      then comp;

      case TORN_LOOP(strict = strict) algorithm
        // ToDo: update linearity here
        strict.jac := jac;
        comp.strict := strict;
      then comp;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong component: " + toString(comp)});
      then fail();
    end match;
  end addLoopJacobian;

  function getLoopResiduals
    input StrongComponent comp;
    output list<Pointer<Variable>> residuals;
  algorithm
    residuals := match comp
      case TORN_LOOP()  then Tearing.getResidualVars(comp.strict);
                        else {};
    end match;
  end getLoopResiduals;

  function isDiscrete
    "checks if all equations are discrete"
    input StrongComponent comp;
    output Boolean b;
  protected
    function bool_ident "just for usage in List.all"
      input output Boolean b;
    end bool_ident;
  algorithm
    b := match comp
      case SINGLE_EQUATION()        then Equation.isDiscrete(comp.eqn);
      case SINGLE_ARRAY()           then Equation.isDiscrete(comp.eqn);
      case SINGLE_ALGORITHM()       then Equation.isDiscrete(comp.eqn);
      case SINGLE_RECORD_EQUATION() then Equation.isDiscrete(comp.eqn);
      case SINGLE_WHEN_EQUATION()   then Equation.isDiscrete(comp.eqn);
      case SINGLE_IF_EQUATION()     then Equation.isDiscrete(comp.eqn);
      case SLICED_EQUATION()        then Equation.isDiscrete(Slice.getT(comp.eqn));
      case ENTWINED_EQUATION()      then List.all(list(isDiscrete(c) for c in comp.entwined_slices), bool_ident);
      case ALGEBRAIC_LOOP()         then not comp.mixed;
      case TORN_LOOP()              then not comp.mixed;
      case ALIAS()                  then isDiscrete(comp.original);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong component: " + toString(comp)});
      then fail();
    end match;
  end isDiscrete;

  // ############################################################
  //                Protected Functions and Types
  // ############################################################

protected
  function createScalar
    // UNUSED AND BROKEN!
    input list<Integer> comp_indices;
    input array<Integer> eqn_to_var;
    input VariablePointers vars;
    input EquationPointers eqns;
    output StrongComponent comp;
  algorithm
    // ToDo: add all other cases!
    comp := match comp_indices
      local
        Integer i;
        list<Integer> array_comp_indices;
        list<Pointer<Variable>> loop_vars;
        list<Pointer<Equation>> loop_eqns;

      case {i} then SINGLE_EQUATION(
                      var     = VariablePointers.getVarAt(vars, eqn_to_var[i]),
                      eqn     = EquationPointers.getEqnAt(eqns, i),
                      status  = NBSolve.Status.UNPROCESSED
                    );

      case _ algorithm
        //(loop_vars, loop_eqns) := getLoopPairs(comp_indices, mapping, eqn_to_var, vars, eqns);
      then ALGEBRAIC_LOOP(
          vars    = {},
          eqns    = {},
          jac     = NONE(),
          mixed   = false,
          status  = NBSolve.Status.UNPROCESSED
        );

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end createScalar;

  function createPseudoScalar
    input list<Integer> comp_indices;
    input array<Integer> eqn_to_var;
    input Adjacency.Mapping mapping;
    input VariablePointers vars;
    input EquationPointers eqns;
    output StrongComponent comp;
  algorithm
    // ToDo: add all other cases!
    comp := match comp_indices
      local
        Integer i, var_scal_idx, var_arr_idx, var_start_idx, size;
        list<Integer> sizes, vals;
        Type ty;
        ComponentRef cref;
        Pointer<Variable> var;
        Pointer<Equation> eqn;
        list<Pointer<Variable>> comp_vars;
        list<Pointer<Equation>> comp_eqns;

      case {i} algorithm
        var_scal_idx := eqn_to_var[i];
        var_arr_idx := mapping.var_StA[var_scal_idx];
        var := VariablePointers.getVarAt(vars, var_arr_idx);
        eqn := EquationPointers.getEqnAt(eqns, mapping.eqn_StA[i]);
        (var_start_idx, size) := mapping.var_AtS[var_arr_idx];
        if size > 1 then
          // create the scalar variable and make sliced equation
          Variable.VARIABLE(name = cref, ty = ty) := Pointer.access(var);
          sizes := list(Dimension.size(dim) for dim in Type.arrayDims(ty));
          vals := Slice.indexToLocation(var_scal_idx-var_start_idx, sizes);
          cref := ComponentRef.mergeSubscripts(list(Subscript.INDEX(Expression.INTEGER(val+1)) for val in vals), cref);
          comp := SLICED_EQUATION(cref, Slice.SLICE(var, {}), Slice.SLICE(eqn, {}), NBSolve.Status.UNPROCESSED);
        else
          // just create a regular equation
          comp := match Pointer.access(eqn)
            case Equation.WHEN_EQUATION()   then SINGLE_WHEN_EQUATION({var}, eqn, NBSolve.Status.UNPROCESSED);
            case Equation.IF_EQUATION()     then SINGLE_IF_EQUATION({var}, eqn, NBSolve.Status.UNPROCESSED);
            case Equation.ALGORITHM()       then SINGLE_ALGORITHM({var}, eqn, NBSolve.Status.UNPROCESSED);
                                            else SINGLE_EQUATION(var, eqn, NBSolve.Status.UNPROCESSED);
          end match;
        end if;
      then comp;

      case _ algorithm
        (comp_vars, comp_eqns) := getLoopPairs(comp_indices, eqn_to_var, mapping, vars, eqns);
        comp := match (comp_vars, comp_eqns)
          case (_, {eqn}) guard(Equation.isWhenEquation(eqn))
          then SINGLE_WHEN_EQUATION(
            vars    = comp_vars,
            eqn     = eqn,
            status  = NBSolve.Status.UNPROCESSED
          );

          case (_, {eqn}) guard(Equation.isIfEquation(eqn))
          then SINGLE_IF_EQUATION(
            vars    = comp_vars,
            eqn     = eqn,
            status  = NBSolve.Status.UNPROCESSED
          );

          case ({var}, {eqn}) guard(Equation.isArrayEquation(eqn))
          then SINGLE_ARRAY(
            var     = var,
            eqn     = eqn,
            status  = NBSolve.Status.UNPROCESSED
          );

          case ({var}, {eqn}) guard(Equation.isRecordEquation(eqn))
          then SINGLE_RECORD_EQUATION(
            var     = var,
            eqn     = eqn,
            status  = NBSolve.Status.UNPROCESSED
          );

          case (_, {eqn}) guard(Equation.isAlgorithm(eqn))
          then SINGLE_ALGORITHM(
            vars    = comp_vars,
            eqn     = eqn,
            status  = NBSolve.Status.UNPROCESSED
          );

          else ALGEBRAIC_LOOP(
            vars    = comp_vars,
            eqns    = comp_eqns,
            jac     = NONE(),
            mixed   = false,
            status  = NBSolve.Status.UNPROCESSED
          );
        end match;
      then comp;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end createPseudoScalar;

  function getLoopPairs
    "adds the equation and matched variable to accumulated lists.
    used to collect algebraic loops
    ToDo: currently assumes full dependency - update with Slice structures!"
    input list<Integer> comp_indices;
    input array<Integer> eqn_to_var;
    input Adjacency.Mapping mapping;
    input VariablePointers vars;
    input EquationPointers eqns;
    output list<Pointer<Variable>> acc_vars = {};
    output list<Pointer<Equation>> acc_eqns = {};
  protected
    Integer var_idx, var_arr_idx, eqn_arr_idx;
    // when adding slices these should be maps collecting scalar indices instead
    UnorderedSet<Integer> var_set = UnorderedSet.new(intMod, intEq, listLength(comp_indices));
    UnorderedSet<Integer> eqn_set = UnorderedSet.new(intMod, intEq, listLength(comp_indices));
  algorithm
    for eqn_idx in comp_indices loop
      var_idx := eqn_to_var[eqn_idx];
      var_arr_idx := mapping.var_StA[var_idx];
      eqn_arr_idx := mapping.eqn_StA[eqn_idx];
      if not UnorderedSet.contains(var_arr_idx, var_set) then
        UnorderedSet.add(var_arr_idx, var_set);
        acc_vars := VariablePointers.getVarAt(vars, var_arr_idx) :: acc_vars;
      end if;
      if not UnorderedSet.contains(eqn_arr_idx, eqn_set) then
        UnorderedSet.add(eqn_arr_idx, eqn_set);
        acc_eqns := EquationPointers.getEqnAt(eqns, eqn_arr_idx) :: acc_eqns;
      end if;
    end for;
  end getLoopPairs;

  function updateDependencyMap
    input ComponentRef cref                                   "cref representing current equation";
    input list<ComponentRef> dependencies                     "the dependency crefs";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map  "unordered map to save the dependencies";
    input JacobianType jacType                                "gives context";
  protected
    list<ComponentRef> tmp_dependencies, fixed_dependencies = {};
  algorithm
    try
      // replace non derivative dependencies with their previous dependencies (also remove self dependency)
      // (be careful with algebraic loops. this here assumes that cyclic dependencies have already been resolved)
      if jacType == NBJacobian.JacobianType.SIMULATION then
        for dep in listReverse(dependencies) loop
          if BVariable.checkCref(dep, BVariable.isState) then
            fixed_dependencies := dep :: fixed_dependencies;
          else
            tmp_dependencies := list(tmp for tmp guard(not ComponentRef.isEqual(tmp, cref)) in UnorderedMap.getSafe(dep, map));
            fixed_dependencies := listAppend(tmp_dependencies, fixed_dependencies);
          end if;
        end for;
      else
        // only remove self dependency
        fixed_dependencies := list(tmp for tmp guard(not ComponentRef.isEqual(tmp, cref)) in dependencies);
      end if;
      // update the current value (res/tmp) --> {independent vars}
      UnorderedMap.add(cref, fixed_dependencies, map);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
    end try;
  end updateDependencyMap;

  annotation(__OpenModelica_Interface="backend");
end NBStrongComponent;
