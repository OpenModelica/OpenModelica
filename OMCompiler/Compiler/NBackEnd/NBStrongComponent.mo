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
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import Causalize = NBCausalize;
  import BVariable = NBVariable;
  import BEquation = NBEquation;
  import NBEquation.Equation;
  import NBEquation.EquationAttributes;
  import HashTableCrToCrLst = NBHashTableCrToCrLst;
  import Matching = NBMatching;
  import Tearing = NBTearing;

  // Util imports
  import Pointer;
  import StringUtil;
  import UnorderedMap;

public
  record SINGLE_EQUATION
    Pointer<Variable> var;
    Pointer<Equation> eqn;
  end SINGLE_EQUATION;

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
          str := str + "### Variable:" + Variable.toString(Pointer.access(comp.var), "\t") + "\n";
          str := str + "### Equation:" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_ARRAY()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Array");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_ALGORITHM()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Algorithm");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_RECORD_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single Record Equation");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_WHEN_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single When-Equation");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
      then str;

      case SINGLE_IF_EQUATION()
        algorithm
          str := StringUtil.headline_3("BLOCK" + indexStr + ": Single If-Equation");
          str := str + "### Variables:\n";
          for var in comp.vars loop
            str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
          end for;
          str := str + "\n### Equation:" + Equation.toString(Pointer.access(comp.eqn), "\t") + "\n";
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
    input BVariable.VariablePointers vars;
    input BEquation.EquationPointers eqns;
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
    HashTable. Saves both directions."
    input StrongComponent comp                    "strong component to be analyzed";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map "unordered map to save the dependencies";
    input Boolean jacobian = true                 "true if the analysis is for jacobian sparsity pattern";
  algorithm
    _ := match comp
      local
        list<ComponentRef> dependencies = {}, loop_vars = {}, tmp;
        BEquation.EquationAttributes attr;
        Pointer<Variable> dependentVar;
        Tearing strict;

      case SINGLE_EQUATION() algorithm
        dependencies := Equation.collectCrefs(Pointer.access(comp.eqn), function getDependentCref(map = map));
        attr := BEquation.Equation.getAttributes(Pointer.access(comp.eqn));
        dependentVar := if jacobian then BEquation.EquationAttributes.getResidualVar(attr) else comp.var;
        updateDependencyMap(BVariable.getVarName(dependentVar), dependencies, map);
      then ();

      case SINGLE_ARRAY() algorithm
        dependencies := Equation.collectCrefs(Pointer.access(comp.eqn), function getDependentCref(map = map));
        if jacobian then
          attr := BEquation.Equation.getAttributes(Pointer.access(comp.eqn));
          dependentVar := BEquation.EquationAttributes.getResidualVar(attr);
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
        for eqn in strict.residual_eqns loop
          tmp := Equation.collectCrefs(Pointer.access(eqn), function getDependentCref(map = map));
          dependencies := listAppend(tmp, dependencies);
        end for;

        // traverse inner equations and collect loop vars and dependencies
        for i in 1:arrayLength(strict.innerEquations) loop
          // collect inner equation dependencies
          tmp := Equation.collectCrefs(Pointer.access(strict.innerEquations[i].eqn), function getDependentCref(map = map));
          dependencies := listAppend(tmp, dependencies);

          // collect inner loop variables
          for var in strict.innerEquations[i].vars loop
            loop_vars := BVariable.getVarName(var) :: loop_vars;
          end for;
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

protected
  function createScalar
    input list<Integer> comp_indices;
    input array<Integer> eqn_to_var;
    input BVariable.VariablePointers vars;
    input BEquation.EquationPointers eqns;
    output StrongComponent comp;
  algorithm
    // ToDo: add all other cases!
    comp := match comp_indices
      local
        Integer i;
        list<Pointer<Variable>> acc_vars = {};
        list<Pointer<Equation>> acc_eqns = {};

      case {i} then SINGLE_EQUATION(
                      var = BVariable.VariablePointers.getVarAt(vars, eqn_to_var[i]),
                      eqn = BEquation.EquationPointers.getEqnAt(eqns, i)
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

  function getLoopPair
    input Integer idx;
    input array<Integer> eqn_to_var;
    input BVariable.VariablePointers vars;
    input BEquation.EquationPointers eqns;
    input output list<Pointer<Variable>> acc_vars;
    input output list<Pointer<Equation>> acc_eqns;
  algorithm
    acc_vars := BVariable.VariablePointers.getVarAt(vars, eqn_to_var[idx]) :: acc_vars;
    acc_eqns := BEquation.EquationPointers.getEqnAt(eqns, idx) :: acc_eqns;
  end getLoopPair;

  function getDependentCref
    input output ComponentRef cref          "the cref to check";
    input Pointer<list<ComponentRef>> acc   "accumulator for relevant crefs";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map   "unordered map to check for relevance";
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
    input ComponentRef cref                       "cref representing current equation";
    input list<ComponentRef> dependencies         "the dependency crefs";
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
