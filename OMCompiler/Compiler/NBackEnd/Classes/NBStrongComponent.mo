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
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers, EquationAttributes};
  import Matching = NBMatching;
  import Sorting = NBSorting;
  import Tearing = NBTearing;
  import NBVariable.VariablePointers;

  // Util imports
  import BackendUtil = NBBackendUtil;
  import Pointer;
  import Slice = NBSlice;
  import StringUtil;
  import UnorderedMap;

public
  record SINGLE_EQUATION
    Pointer<Variable> var;
    Pointer<Equation> eqn;
  end SINGLE_EQUATION;

  record SLICED_EQUATION
    ComponentRef var_cref       "variable slice (cref to solve for)";
    list<Integer> eqn_indices   "equation slice (zero based equation indices)";
    Pointer<Variable> var       "full unsliced variable";
    Pointer<Equation> eqn       "full unsliced equation";
  end SLICED_EQUATION;

  record SINGLE_ARRAY
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_ARRAY;

  record SINGLE_ALGORITHM
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_ALGORITHM;

  record SINGLE_RECORD_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_RECORD_EQUATION;

  record SINGLE_WHEN_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_WHEN_EQUATION;

  record SINGLE_IF_EQUATION
    list<Pointer<Variable>> vars;
    Pointer<Equation> eqn;
  end SINGLE_IF_EQUATION;

  record ALGEBRAIC_LOOP
    list<Pointer<Variable>> vars;
    list<Pointer<Equation>> eqns;
    Option<BackendDAE> jac;
    Boolean mixed         "true for system that has discrete dependencies to the
                          iteration variables";
  end ALGEBRAIC_LOOP;

  record TORN_LOOP
    Integer idx;
    Tearing strict;
    Option<Tearing> casual;
    Boolean linear;
    Boolean mixed "true for system that discrete dependencies to the iteration variables";
  end TORN_LOOP;

  function toString
    input StrongComponent comp;
    input Integer index = -1;
    output String str;
  protected
    String indexStr = if index > 0 then " " + intString(index) else "";
  algorithm
    str := match comp
      local
        Tearing casual;

      case SINGLE_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Equation");
          str := str + "### Variable:\n" + Variable.toString(Pointer.access(comp.var), "\t") + "\n";
          str := str + "### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SLICED_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Sliced Equation");
          str := str + "### Variable:\n\t" + ComponentRef.toString(comp.var_cref) + "\n";
          str := str + "### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
          str := str + "    with slices: " + List.toString(comp.eqn_indices, intString) + "\n";
      then str;

      case SINGLE_ARRAY()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Array");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_ALGORITHM()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Algorithm");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_RECORD_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Record Equation");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_WHEN_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single When-Equation");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_IF_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single If-Equation");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:\n" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case ALGEBRAIC_LOOP()
        algorithm
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

      case TORN_LOOP()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Torn Algebraic Loop (Linear = " + boolString(comp.linear) + ", Mixed = " + boolString(comp.mixed) + ")");
          str := str + Tearing.toString(comp.strict, "Strict Tearing Set");
          if isSome(comp.casual) then
            SOME(casual) := comp.casual;
            str := str + Tearing.toString(casual, "Casual Tearing Set");
          end if;
      then str;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end toString;

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
        Integer i, mode, first_eqn;
        Sorting.PseudoBucketValue val;
        Equation eqn;
        Pointer<Equation> eqn_ptr;

      case {i} guard(Adjacency.CausalizeModes.contains(i, modes)) algorithm
        if bucket.marks[i] then
          // has already been created
          comp := NONE();
        else
          // get mode and bucket
          mode  := Adjacency.CausalizeModes.get(i, eqn_to_var[i], modes);
          val   := Sorting.PseudoBucket.get(mapping.eqn_StA[i], mode, bucket);

          // get and save sliced equation
          eqn_ptr := EquationPointers.getEqnAt(eqns, mapping.eqn_StA[i]);
          first_eqn := Adjacency.Mapping.getEqnFirst(i, mapping);

          comp := SOME(SLICED_EQUATION(
            var_cref    = val.cref_to_solve,
            eqn_indices = list(idx - first_eqn for idx in listReverse(val.eqn_scal_indices)),
            var         = BVariable.getVarPointer(val.cref_to_solve),
            eqn         = eqn_ptr
          ));

          // mark all scalar indices
          for scal_idx in val.eqn_scal_indices loop
            arrayUpdate(bucket.marks, scal_idx, true);
          end for;
        end if;
      then comp;

      // if it is no array structure just use scalar
      else SOME(createPseudoScalar(comp_indices, eqn_to_var, mapping, vars, eqns));
    end match;
  end createPseudo;

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
      then SINGLE_EQUATION(residualVar, eq_ptr);

      case Equation.ARRAY_EQUATION(attr = EquationAttributes.EQUATION_ATTRIBUTES(residualVar = SOME(residualVar)))
      then SINGLE_ARRAY({residualVar}, eq_ptr);

      // maybe check for type SINGLE // ARRAY ?
      case Equation.SIMPLE_EQUATION(attr = EquationAttributes.EQUATION_ATTRIBUTES(residualVar = SOME(residualVar)))
      then SINGLE_EQUATION(residualVar, eq_ptr);

      /* are other residuals possible? */

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;

    Pointer.update(acc, comp :: Pointer.access(acc));
  end makeDAEModeResidualTraverse;

  function getDependentCrefs
    "Collects dependent crefs in current comp and saves them in the
     unordered map. Saves both directions."
    input StrongComponent comp                                "strong component to be analyzed";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map  "unordered map to save the dependencies";
    input Boolean jacobian = true                             "true if the analysis is for jacobian sparsity pattern";
  algorithm
    _ := match comp
      local
        list<ComponentRef> dependencies = {}, loop_vars = {}, tmp;
        EquationAttributes attr;
        Pointer<Variable> dependentVar;
        Tearing strict;
        Pointer<Equation> eqn;

      case SINGLE_EQUATION() algorithm
        dependencies := Equation.collectCrefs(Pointer.access(comp.eqn), function getDependentCref(map = map));
        attr := Equation.getAttributes(Pointer.access(comp.eqn));
        dependentVar := if jacobian then EquationAttributes.getResidualVar(attr) else comp.var;
        updateDependencyMap(BVariable.getVarName(dependentVar), dependencies, map);
      then ();

      case SLICED_EQUATION() algorithm
        dependencies := Equation.collectCrefs(Pointer.access(comp.eqn), function getDependentCref(map = map));
        attr := Equation.getAttributes(Pointer.access(comp.eqn));
        // assume full dependency
        dependentVar := if jacobian then EquationAttributes.getResidualVar(attr) else BVariable.getVarPointer(comp.var_cref);
        updateDependencyMap(BVariable.getVarName(dependentVar), dependencies, map);
      then ();

      case SINGLE_ARRAY() algorithm
        dependencies := Equation.collectCrefs(Pointer.access(comp.eqn), function getDependentCref(map = map));
        if jacobian then
          attr := Equation.getAttributes(Pointer.access(comp.eqn));
          dependentVar := EquationAttributes.getResidualVar(attr);
          updateDependencyMap(BVariable.getVarName(dependentVar), dependencies, map);
        else
          for var in comp.vars loop
            updateDependencyMap(BVariable.getVarName(var), dependencies, map);
          end for;
        end if;
      then ();

      case TORN_LOOP(strict = strict) algorithm
        // collect iteration loop vars
        for var in strict.iteration_vars loop
          loop_vars := BVariable.getVarName(var) :: loop_vars;
        end for;

        // traverse residual equations and collect dependencies
        for slice in strict.residual_eqns loop
          // ToDo: does this work properly for arrays?
          tmp := Equation.collectCrefs(Pointer.access(Slice.getT(slice)), function getDependentCref(map = map));
          dependencies := listAppend(tmp, dependencies);
        end for;

        // traverse inner equations and collect loop vars and dependencies
        for i in 1:arrayLength(strict.innerEquations) loop
          // collect inner equation dependencies
          tmp := Equation.collectCrefs(Pointer.access(strict.innerEquations[i].eqn), function getDependentCref(map = map));
          dependencies := listAppend(tmp, dependencies);

          // collect inner loop variables
          loop_vars := BVariable.getVarName(strict.innerEquations[i].var) :: loop_vars;
        end for;

        // add all dependencies
        for cref in loop_vars loop
          updateDependencyMap(cref, dependencies, map);
        end for;
      then ();

      /* ToDo add the others and let else case fail! */

      else ();
    end match;
  end getDependentCrefs;

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

  // ############################################################
  //                Protected Functions and Types
  // ############################################################

protected
  function createScalar
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
        list<Pointer<Variable>> acc_vars = {};
        list<Pointer<Equation>> acc_eqns = {};

      case {i} then SINGLE_EQUATION(
                      var = VariablePointers.getVarAt(vars, eqn_to_var[i]),
                      eqn = EquationPointers.getEqnAt(eqns, i)
                    );

      case _ algorithm
        for i in comp_indices loop
          (acc_vars, acc_eqns) := getLoopPair(i, eqn_to_var, vars, eqns, acc_vars, acc_eqns);
        end for;
      then ALGEBRAIC_LOOP(
          vars    = acc_vars,
          eqns    = acc_eqns,
          jac     = NONE(),
          mixed   = false
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
        list<Pointer<Variable>> acc_vars = {};
        list<Pointer<Equation>> acc_eqns = {};

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
          vals := BackendUtil.indexToFrame(var_scal_idx-var_start_idx, sizes);
          cref := ComponentRef.mergeSubscripts(list(Subscript.INDEX(Expression.INTEGER(val+1)) for val in vals), cref);
          comp := SLICED_EQUATION(cref, {}, var, eqn);
        else
          // just create a regular equation
          comp := SINGLE_EQUATION(var, eqn);
        end if;
      then comp;

      case _ algorithm
        for i in comp_indices loop
          (acc_vars, acc_eqns) := getLoopPair(i, eqn_to_var, vars, eqns, acc_vars, acc_eqns);
        end for;
      then ALGEBRAIC_LOOP(
          vars    = acc_vars,
          eqns    = acc_eqns,
          jac     = NONE(),
          mixed   = false
        );

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end createPseudoScalar;

  function getLoopPair
    "adds the equation and matched variable to accumulated lists.
    used to collect algebraic loops"
    input Integer idx;
    input array<Integer> eqn_to_var;
    input VariablePointers vars;
    input EquationPointers eqns;
    input output list<Pointer<Variable>> acc_vars;
    input output list<Pointer<Equation>> acc_eqns;
  algorithm
    acc_vars := VariablePointers.getVarAt(vars, eqn_to_var[idx]) :: acc_vars;
    acc_eqns := EquationPointers.getEqnAt(eqns, idx) :: acc_eqns;
  end getLoopPair;

  function getDependentCref
    "checks if crefs are relevant in the given context and collects them"
    input output ComponentRef cref                              "the cref to check";
    input Pointer<list<ComponentRef>> acc                       "accumulator for relevant crefs";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map    "unordered map to check for relevance";
  protected
    list<ComponentRef> dependencies;
  algorithm
    if UnorderedMap.contains(cref, map) then
      dependencies := UnorderedMap.getSafe(cref, map);
      if listEmpty(dependencies) then
        // if no previous dependencies are found, it is an independent variable
        Pointer.update(acc, cref :: Pointer.access(acc));
      else
        // if previous dependencies are found, it is a temporary inner variable
        // recursively add all their dependencies
        Pointer.update(acc, listAppend(dependencies, Pointer.access(acc)));
      end if;
    end if;
  end getDependentCref;

  function updateDependencyMap
    input ComponentRef cref                                   "cref representing current equation";
    input list<ComponentRef> dependencies                     "the dependency crefs";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map  "unordered map to save the dependencies";
  algorithm
    try
      // update the current value (res/tmp) --> {independent vars}
      UnorderedMap.add(cref, dependencies, map);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
    end try;
  end updateDependencyMap;

  annotation(__OpenModelica_Interface="backend");
end NBStrongComponent;
