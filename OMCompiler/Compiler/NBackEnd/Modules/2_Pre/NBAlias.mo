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
encapsulated package NBAlias
"file:        NBAlias.mo
 package:     NBAlias
 description: This file contains the functions for the alias elimination module.
              It eliminates alias variables (ToDo: and resolves simple index reduction problems).
"

// ToDo:
// 1. simple state rules (with derivative replacement)
//    - state = state
//    - state = alg
//    - state = time
//    - state = const
// 2. write rateVar() and decide if we want an auxiliary for each set
//    - rateVar() --> mergeAttributes()
// 3. post causalize alias elimination
//    - for the ODE
//    - for jacobians/hessians (once we got hessians)
//    - for strong components in general
// 4. simplify only replaced equations and remove simplify2 module
//    - probably not that trivial
//    - Equation mapExp function that returns true if something was replaced
//    - EquationArray map function that accumulates pointers if function returns true
//    - simplify all equations in pointer list

// 5. trivial solution a = b; a = -b; (or other cyclic sets)
//    - take an equation from the set, get both crefs in it (a,b)
//    - solve for a -> set a as known
//    - solve the rest of the set with causalize
//    - replacements a -> what it solves for in eq1 and apply on all eq in set
//    - find equation that solves b, and solve for b. add to replacements
//    - apply replacements on all eq

public
  import Module = NBModule;
protected
  // OF imports
  import DAE;

  // NF imports
  import BackendExtension = NFBackendExtension;
  import NFBackendExtension.{StateSelect, TearingSelect};
  import NFBackendExtension.VariableKind;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import ExpressionIterator = NFExpressionIterator;
  import Type = NFType;
  import Operator = NFOperator;
  import Variable = NFVariable;
  import NFFlatten.FunctionTreeImpl;
  import NFPrefixes.Variability;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Causalize = NBCausalize;
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.{DifferentiationType, DifferentiationArguments};
  import NBEquation.{Equation, EquationAttributes, EquationKind, EquationPointers, EqData, Iterator};
  import Replacements = NBReplacements;
  import SimplifyExp = NFSimplifyExp;
  import Solve = NBSolve;
  import NBSolve.Status;
  import StrongComponent = NBStrongComponent;
  import Tearing = NBTearing;
  import NBVariable.{VariablePointers, VarData};

  // Util imports
  import MetaModelica.Dangerous;
  import StringUtil;
  import UnorderedMap;
  import UnorderedSet;
public

  // ==========================================================================
  //               Single Variable constants and functions
  // ==========================================================================
  constant Real NOMINAL_THRESHOLD = 1000.0;

  function main
    "Wrapper function for any alias removal function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
  protected
    Module.aliasInterface func;
  algorithm
    (func) := getModule();

    bdae := match bdae
      local
        VarData varData         "Data containing variable pointers";
        EqData eqData           "Data containing equation pointers";

      case BackendDAE.MAIN(varData = varData, eqData = eqData)
        algorithm
          (varData, eqData) := func(varData, eqData);
          // allways apply clock alias
          (varData, eqData) := aliasClocks(varData, eqData);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case BackendDAE.HESSIAN(varData = varData, eqData = eqData)
        algorithm
          (varData, eqData) := func(varData, eqData);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.aliasInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS)
  algorithm
    func := match flag
      case "default" then aliasDefault;
      /* ... New alias modules have to be added here */
      else fail();
    end match;
  end getModule;

protected
  uniontype AliasSet "gets accumulated to find sets of alias equations and solve them"
    record ALIAS_SET
      list<ComponentRef> simple_variables         "list of all variables in this set";
      list<Pointer<Equation>> simple_equations    "list of all equations in this set";
      Option<Pointer<Equation>> const_opt         "optional constant binding of one variable";
    end ALIAS_SET;

    function toString
      input AliasSet set;
      output String str;
    algorithm
      if isSome(set.const_opt) then
        str := "\tConstant/Parameter Binding: "
          + Equation.toString(Pointer.access(Util.getOption(set.const_opt))) + "\n";
      else
        str := "\t<No Constant/Parameter Binding>\n";
      end if;
      if listEmpty(set.simple_equations) then
        str := str + "\t###<No Set Equations>\n";
      else
        str := str + "\t### Set Equations:\n";
        for eq in set.simple_equations loop
          str := str + Equation.toString(Pointer.access(eq), "\t") + "\n";
        end for;
      end if;
    end toString;
  end AliasSet;

  constant AliasSet EMPTY_ALIAS_SET = ALIAS_SET({}, {}, NONE());

  // needed for unordered map
  type SetPtr = Pointer<AliasSet>;

  uniontype CrefTpl "used for findCrefs()"
    record CREF_TPL
      Boolean cont                "false if search already resulted in non simple structure";
      Integer varCount            "variable count";
      Integer paramCount          "parameter/constant count";
      list<ComponentRef> cr_lst   "list of found variables for replacement";
    end CREF_TPL;
  end CrefTpl;

  constant CrefTpl EMPTY_CREF_TPL = CREF_TPL(true, 0, 0, {});
  constant CrefTpl FAILED_CREF_TPL = CREF_TPL(false, 0, 0, {});

  function aliasDefault
    "STEPS:
      1. collect alias sets (variables, equations, optional constant binding)
      2. balance sets - choose variable to keep if necessary
      3. match/sort set (linear w.r.t. unknowns since all equations contain two crefs at max and are simple/linear)
      4. apply replacements
      5. save replacements in bindings of alias variables
    "
    extends Module.aliasInterface;
  algorithm
    (varData, eqData) := match (varData, eqData)
      local
        UnorderedMap<ComponentRef, Expression> replacements;
        EquationPointers newEquations;
        list<Pointer<Variable>> alias_vars, const_vars, non_trivial_alias;
        list<Pointer<Equation>> non_trivial_eqs;

      case (BVariable.VAR_DATA_SIM(), BEquation.EQ_DATA_SIM())
        algorithm
          // -----------------------------------
          //            1. 2. 3.
          // -----------------------------------
          (replacements, newEquations) := aliasCausalize(varData.unknowns, eqData.simulation, "Simulation");

          // -----------------------------------
          // 4. apply replacements
          // 5. save replacements in bindings of alias variables
          // -----------------------------------
          (eqData, varData) := Replacements.applySimple(eqData, varData, replacements);
          alias_vars := list(BVariable.getVarPointer(cref) for cref in UnorderedMap.keyList(replacements));

          // save new equations and compress affected arrays(some might have been removed)
          eqData.simulation := EquationPointers.compress(newEquations);
          eqData.equations  := EquationPointers.compress(eqData.equations);
          eqData.continuous := EquationPointers.compress(eqData.continuous);
          eqData.discretes  := EquationPointers.compress(eqData.discretes);

          // remove alias vars from all relevant arrays
          varData.variables   := VariablePointers.removeList(alias_vars, varData.variables);
          varData.unknowns    := VariablePointers.removeList(alias_vars, varData.unknowns);
          varData.algebraics  := VariablePointers.removeList(alias_vars, varData.algebraics);
          varData.states      := VariablePointers.removeList(alias_vars, varData.states);
          varData.discretes   := VariablePointers.removeList(alias_vars, varData.discretes);
          varData.clocks      := VariablePointers.removeList(alias_vars, varData.clocks);
          varData.initials    := VariablePointers.removeList(alias_vars, varData.initials);

          // categorize alias vars and sort them to the correct arrays
          (non_trivial_alias, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasNonTrivialAliasBinding);

          // split off constant alias
          // update constant start values and add to parameters
          // otherwise they would not show in the result file
          (const_vars, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasConstOrParamAliasBinding);
          for var in const_vars loop
            BVariable.setVarKind(var, VariableKind.PARAMETER(NONE()));
            BVariable.setBindingAsStartAndFix(var);
          end for;
          varData.parameters := VariablePointers.addList(const_vars, varData.parameters);
          varData.knowns := VariablePointers.addList(const_vars, varData.knowns);

          // add only the actual 1/-1 alias vars to alias vars
          varData.aliasVars := VariablePointers.addList(alias_vars, varData.aliasVars);
          varData.nonTrivialAlias := VariablePointers.addList(non_trivial_alias, varData.nonTrivialAlias);

          // add non trivial alias to removed
          non_trivial_eqs := list(Equation.generateBindingEquation(var, eqData.uniqueIndex, false) for var in non_trivial_alias);
          eqData.removed := EquationPointers.addList(non_trivial_eqs, eqData.removed);
          //eqData.equations := EquationPointers.addList(non_trivial_eqs, eqData.equations);
      then (varData, eqData);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end aliasDefault;

  function aliasClocks
    "STEPS:
      1. collect alias sets (variables, equations, optional constant binding)
      2. balance sets - choose variable to keep if necessary
      3. match/sort set (linear w.r.t. unknowns since all equations contain two crefs at max and are simple/linear)
      4. apply replacements
      5. save replacements in bindings of alias variables
    "
      extends Module.aliasInterface;
  algorithm
    (varData, eqData) := match (varData, eqData)
      local
        UnorderedMap<ComponentRef, Expression> replacements;
        EquationPointers newEquations;
        list<Pointer<Variable>> alias_vars;

      case (BVariable.VAR_DATA_SIM(), BEquation.EQ_DATA_SIM())
        algorithm
          // -----------------------------------
          //            1. 2. 3.
          // -----------------------------------
          (replacements, newEquations) := aliasCausalize(varData.clocks, eqData.clocked, "Clocked");

          // -----------------------------------
          // 4. apply replacements
          // 5. save replacements in bindings of alias variables
          // -----------------------------------
          (eqData, varData) := Replacements.applySimple(eqData, varData, replacements);
          alias_vars := list(BVariable.getVarPointer(cref) for cref in UnorderedMap.keyList(replacements));

          // save new equations and compress affected arrays(some might have been removed)
          eqData.clocked    := EquationPointers.compress(newEquations);

          // remove alias variables from clocks and add to alias
          varData.clocks    := VariablePointers.removeList(alias_vars, varData.clocks);
          varData.aliasVars := VariablePointers.addList(alias_vars, varData.aliasVars);
      then (varData, eqData);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end aliasClocks;

  function aliasCausalize
    "STEPS:
      1. collect alias sets (variables, equations, optional constant binding)
      2. balance sets - choose variable to keep if necessary
      3. match/sort set (linear w.r.t. since all equations contain two unknown crefs at max and are simple/linear)
    "
    input VariablePointers variables;
    input EquationPointers equations;
    input String context;
    output UnorderedMap<ComponentRef, Expression> replacements;
    output EquationPointers newEquations;
  protected
    Integer size, setIdx = 1;
    UnorderedMap<ComponentRef, SetPtr> map;
    list<AliasSet> sets;
  algorithm
    // ------------------------------------------------------------------------------
    // 1. collect alias sets (variables, equations, optional constant binding)
    // ------------------------------------------------------------------------------
    // collect (cref) -> (simpleSet) hashtable
    size := VariablePointers.size(variables);
    map := UnorderedMap.new<SetPtr>(ComponentRef.hash, ComponentRef.isEqual, size);
    (newEquations, map) := NBEquation.EquationPointers.foldRemovePtr(equations, findSimpleEquation, map);

    sets := getSimpleSets(map, size);
    if Flags.isSet(Flags.DUMP_REPL) then
      print(StringUtil.headline_2("[dumprepl] " + context + " Alias Sets:") + "\n");
      if listEmpty(sets) then
        print("<No " + context + " Alias Sets>\n\n");
      else
        for set in sets loop
          print(StringUtil.headline_4("Alias Set " + intString(setIdx) + ":") + AliasSet.toString(set) + "\n");
          setIdx := setIdx + 1;
        end for;
      end if;
    end if;

    // --------------------------------------------------------------------------------------------------------
    // 2. balance sets - choose variable to keep if necessary
    // 3. match/sort set (linear w.r.t. vars since all equations contain two crefs at max and are simple/linear)
    // --------------------------------------------------------------------------------------------------------
    replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual, size);
    for set in sets loop
      replacements := createReplacementRules(set, replacements);
    end for;

    if Flags.isSet(Flags.DUMP_REPL) then
      print(Replacements.simpleToString(replacements) + "\n");
    end if;
  end aliasCausalize;

  function findSimpleEquation
    "Checks if the equation is simple and adds it to the correct set in the hashTable."
    input Pointer<Equation> eq_ptr;
    input output UnorderedMap<ComponentRef, SetPtr> map;
    output Boolean delete = false;
  protected
    Equation eq;
    CrefTpl crefTpl = EMPTY_CREF_TPL;
  algorithm
    eq := Pointer.access(eq_ptr);
    crefTpl := match eq
      case BEquation.SCALAR_EQUATION() guard(isSimpleExp(eq.lhs) and isSimpleExp(eq.rhs)) algorithm
        crefTpl := Expression.fold(eq.rhs, findCrefs, crefTpl);
        crefTpl := Expression.fold(eq.lhs, findCrefs, crefTpl);
      then crefTpl;
      // ToDo: ARRAY_EQUATION RECORD_EQUATION (AUX_EQUATION?)
      case BEquation.ARRAY_EQUATION() guard(isSimpleExp(eq.lhs) and isSimpleExp(eq.rhs)) algorithm
        crefTpl := Expression.fold(eq.rhs, findCrefs, crefTpl);
        crefTpl := Expression.fold(eq.lhs, findCrefs, crefTpl);
      then crefTpl;
      else crefTpl;
    end match;

    (map, delete) := match crefTpl
      local
        SetPtr set_ptr, set1_ptr, set2_ptr;
        AliasSet set, set1, set2;
        ComponentRef cr1, cr2;

      // one variable is connected to a parameter or constant
      case CREF_TPL(cr_lst = {cr1}) algorithm
        if not UnorderedMap.contains(cr1, map) then
          // the variable does not belong to a set -> create new one
          set := EMPTY_ALIAS_SET;
          set.simple_variables := {cr1};
          set.const_opt := SOME(Pointer.create(eq));
          UnorderedMap.add(cr1, Pointer.create(set), map);
        else
          // it already belongs to a set, try to update it and throw error if there already is a const binding
          set_ptr := UnorderedMap.getOrFail(cr1, map);
          set := Pointer.access(set_ptr);
          if isSome(set.const_opt) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to add Equation:\n"
              + Equation.toString(eq) + "\n because the set already contains a constant binding.
              Overdetermined Set!:" + AliasSet.toString(set)});
            fail();
          else
            set.const_opt := SOME(Pointer.create(eq));
            Pointer.update(set_ptr, set);
          end if;
        end if;
      then (map, true);

      // two variable crefs are connected by a simple equation
      case CREF_TPL(cr_lst = {cr1, cr2}) algorithm
        if (UnorderedMap.contains(cr1, map) and UnorderedMap.contains(cr2, map)) then
          // Merge sets
          set1_ptr := UnorderedMap.getOrFail(cr1, map);
          set2_ptr := UnorderedMap.getOrFail(cr2, map);
          set1 := Pointer.access(set1_ptr);
          set2 := Pointer.access(set2_ptr);
          set := EMPTY_ALIAS_SET;

          if referenceEq(set1_ptr, set2_ptr) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to merge following sets " +
                "because they would create a loop. This would create an underdetermined Set!:\n\n" +
                "Trying to merge: " + Equation.toString(eq) + "\n\n" +
                AliasSet.toString(set1) + "\n" + AliasSet.toString(set2)});
            fail();
          elseif (isSome(set1.const_opt) and isSome(set2.const_opt)) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to merge following sets " +
                "because both have a constant binding. This would create an overdetermined Set!:\n\n" +
                AliasSet.toString(set1) + "\n" + AliasSet.toString(set2)});
            fail();
          elseif isSome(set1.const_opt) then
            set.const_opt := set1.const_opt;
          elseif isSome(set2.const_opt) then
            set.const_opt := set2.const_opt;
          end if;

          // try to append the shorter to the longer lists
          if List.compareLength(set1.simple_equations, set2.simple_equations) > 0 then
            set.simple_equations := Pointer.create(eq) :: Dangerous.listAppendDestroy(set2.simple_equations, set1.simple_equations);
          else
            set.simple_equations := Pointer.create(eq) :: Dangerous.listAppendDestroy(set1.simple_equations, set2.simple_equations);
          end if;

          // try to change as few pointer entries as possible
          if List.compareLength(set1.simple_variables, set2.simple_variables) > 0 then
            set.simple_variables := Dangerous.listAppendDestroy(set2.simple_variables, set1.simple_variables);
            Pointer.update(set1_ptr, set);
            for cr in set2.simple_variables loop
              UnorderedMap.add(cr, set1_ptr, map);
            end for;
          else
            set.simple_variables := Dangerous.listAppendDestroy(set2.simple_variables, set1.simple_variables);
            Pointer.update(set2_ptr, set);
            for cr in set1.simple_variables loop
              UnorderedMap.add(cr, set2_ptr, map);
            end for;
          end if;

        elseif UnorderedMap.contains(cr1, map) then
          // Update set
          set_ptr := UnorderedMap.getOrFail(cr1, map);
          set := Pointer.access(set_ptr);
          // add cr2 to variables and add new equation pointer
          set.simple_variables := cr2 :: set.simple_variables;
          set.simple_equations := Pointer.create(eq) :: set.simple_equations;
          Pointer.update(set_ptr, set);
          // add new hash entry for c2
          UnorderedMap.add(cr2, set_ptr, map);
        elseif UnorderedMap.contains(cr2, map) then
          // Update set
          set_ptr := UnorderedMap.getOrFail(cr2, map);
          set := Pointer.access(set_ptr);
          // add cr1 to variables and add new equation pointer
          set.simple_variables := cr1 :: set.simple_variables;
          set.simple_equations := Pointer.create(eq) :: set.simple_equations;
          Pointer.update(set_ptr, set);
          // add new hash entry for c1
          UnorderedMap.add(cr1, set_ptr, map);
        else
          // create new set
          set := EMPTY_ALIAS_SET;
          // add both variables and add new equation pointer
          set.simple_variables := {cr1, cr2};
          set.simple_equations := {Pointer.create(eq)};
          set_ptr := Pointer.create(set);
          // add new hash entry for both variables
          UnorderedMap.add(cr1, set_ptr, map);
          UnorderedMap.add(cr2, set_ptr, map);
        end if;
      then (map, true);

      // no replacements can be done with this equation
      else (map, false);
    end match;
  end findSimpleEquation;

  function findCrefs "BB, kabdelhak
  looks for variable crefs in Expressions, if more than 2 are found stop searching
  also stop if complex structures appear, e.g. IFEXP
  "
    input Expression exp;
    input output CrefTpl tpl;
  algorithm
    tpl := match exp

      case _ guard(not tpl.cont) then FAILED_CREF_TPL;

      // time, parameter or constant found (nothing happens)
      case Expression.CREF()
        guard(BVariable.isParamOrConst(BVariable.getVarPointer(exp.cref)) or ComponentRef.isTime(exp.cref))
      then tpl;

      // fail for record elements for now
      case Expression.CREF()
        guard(Util.isSome(BVariable.getParent(BVariable.getVarPointer(exp.cref))))
      then FAILED_CREF_TPL;

      // variable found
      // 1. not time and not param or const
      // 2. less than two previous variables
      // 3. if it is an array, it has to be the full array. no slice replacement here
      case Expression.CREF()
        guard((tpl.varCount < 2) and not ComponentRef.hasSubscripts(exp.cref))
        algorithm
          // add the variable to the list and bump var count
          tpl.cr_lst := exp.cref :: tpl.cr_lst;
          tpl.varCount := tpl.varCount + 1;
      then tpl;

      // set the continue attribute to false if any fail case is met
      case _ guard(findCrefsFail(exp)) then FAILED_CREF_TPL;

      else tpl;
    end match;
  end findCrefs;

  function findCrefsFail
    "finds all failing cases to stop searching for simple crefs.
    also fails for crefs because viable cases have to be caught
    before invoking this function in findCrefs().
    ToDo: Discuss and find all failing cases"
    input Expression exp;
    output Boolean cont;
  algorithm
    cont := match exp
      case Expression.CREF()      then true;
      case Expression.RELATION()  then true;
      case Expression.IF()        then true;
      case Expression.CALL()      then true;
      case Expression.RECORD()    then true;
                                  else false;
    end match;
  end findCrefsFail;

  function isSimpleExp
    "checks if an expression can be considered simple."
    input Expression exp;
    input output Boolean simple = true;
    output Integer num_cref = 0;
  algorithm
    if not simple then return; end if;
    (simple, num_cref) := match exp
      local
        Integer num_cref_tmp;
        Operator.Op op;

      case Expression.INTEGER()   then (true, 0);
      case Expression.REAL()      then (true, 0);
      case Expression.BOOLEAN()   then (true, 0);
      case Expression.STRING()    then (true, 0);
      case Expression.CREF()      then (true, 1);
      // TODO what about parameters in the denominator, they could be zero, (alias strictness?)
      //case Expression.CREF()      then (true, if ComponentRef.variability(exp.cref) > Variability.NON_STRUCTURAL_PARAMETER then 1 else 0);

      case Expression.CAST()      then isSimpleExp(exp.exp);

      case Expression.UNARY() algorithm
        (simple, num_cref) := isSimpleExp(exp.exp);
        simple := if simple then checkOp(exp.operator, num_cref) else false;
      then (simple, num_cref);

      case Expression.LUNARY() algorithm
        (simple, num_cref) := isSimpleExp(exp.exp);
        simple := if simple then checkOp(exp.operator, num_cref) else false;
      then (simple, num_cref);

      case Expression.BINARY(operator = Operator.OPERATOR(op = op)) algorithm
        (simple, num_cref) := isSimpleExp(exp.exp2);
        // 1/x is not considered simple
        if op == NFOperator.Op.DIV and num_cref <> 0 then simple := false; return; end if;
        (simple, num_cref_tmp) := isSimpleExp(exp.exp1, simple);
        num_cref := num_cref + num_cref_tmp;
        simple := if simple then checkOp(exp.operator, num_cref) else false;
      then (simple, num_cref);

      case Expression.LBINARY() algorithm
        (simple, num_cref) := isSimpleExp(exp.exp1);
        (simple, num_cref_tmp) := isSimpleExp(exp.exp2, simple);
        num_cref := num_cref + num_cref_tmp;
        simple := if simple then checkOp(exp.operator, num_cref) else false;
      then (simple, num_cref);

      case Expression.MULTARY(operator = Operator.OPERATOR(op = op)) algorithm
        for arg in exp.inv_arguments loop
          (simple, num_cref_tmp) := isSimpleExp(arg, simple);
          if not simple then return; end if;
          num_cref := num_cref + num_cref_tmp;
        end for;
        // 1/x is not considered simple
        if op == NFOperator.Op.MUL and num_cref <> 0 then simple := false; return; end if;
        for arg in exp.arguments loop
          (simple, num_cref_tmp) := isSimpleExp(arg, simple);
          if not simple then return; end if;
          num_cref := num_cref + num_cref_tmp;
        end for;
        simple := if simple then checkOp(exp.operator, num_cref) else false;
      then (simple, num_cref);

      else (false, num_cref);
    end match;
  end isSimpleExp;

  function checkOp
    "BB"
    input Operator op;
    input Integer cref_num;
    output Boolean b;
  algorithm
    b := match(op)
      case Operator.OPERATOR(op = NFOperator.Op.ADD)        then true;
      case Operator.OPERATOR(op = NFOperator.Op.SUB)        then true;
      case Operator.OPERATOR(op = NFOperator.Op.UMINUS)     then true;
      case Operator.OPERATOR(op = NFOperator.Op.NOT)        then true;
      case Operator.OPERATOR(op = NFOperator.Op.MUL)        then cref_num < 2;
      case Operator.OPERATOR(op = NFOperator.Op.DIV)        then cref_num < 2;
                                                            else cref_num == 0;
    end match;
  end checkOp;

  function getSimpleSets
    "extracts all simple sets from the hashTable and avoids duplicates by marking variables"
    input UnorderedMap<ComponentRef, SetPtr> map;
    input Integer size;
    output list<AliasSet> sets = {};
  protected
    UnorderedSet<ComponentRef> cref_marks = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, size);
    list<tuple<ComponentRef, SetPtr>> entry_lst;
    ComponentRef simple_cref;
    SetPtr set_ptr;
    AliasSet set;
  algorithm
    entry_lst := UnorderedMap.toList(map);
    for entry in entry_lst loop
      (simple_cref, set_ptr) := entry;
      if not UnorderedSet.contains(simple_cref, cref_marks) then
        set := Pointer.access(set_ptr);
        sets := set :: sets;
        for cr in set.simple_variables loop
          try
            UnorderedSet.addUnique(cr, cref_marks);
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the set for " + ComponentRef.toString(cr) + " was already added."});
          end try;
        end for;
      end if;
    end for;
  end getSimpleSets;

  function createReplacementRules
    "Creates replacement rules from a simple set by causalizing it and replacing the expressions in order"
    input AliasSet set;
    input output UnorderedMap<ComponentRef, Expression> replacements;
  algorithm
    // ToDo: fix variable attributes to keep
    // report errors/warnings
    replacements := match set.const_opt
      local
        Expression rhs;
        Equation solved_eq;
        Pointer<Equation> const_eq, eq;
        list<Pointer<Variable>> alias_vars;
        VariablePointers vars;
        list<Pointer<Variable>> var_lst;
        EquationPointers eqs;
        list<StrongComponent> comps;
        AttributeCollector collector;
        Pointer<Pointer<Variable>> var_to_keep = Pointer.create(Pointer.create(NBVariable.DUMMY_VARIABLE));
        Status status;

      case SOME(const_eq) algorithm
        // there is a constant binding -> no variable will be kept and all will be replaced by a constant
        vars := VariablePointers.fromList(list(BVariable.getVarPointer(cr) for cr in set.simple_variables), true);
        eqs := EquationPointers.fromList(const_eq :: set.simple_equations);
        // causalize the system
        (_, comps) := Causalize.simple(vars, eqs);
        // create replacements from strong components
        Replacements.simple(comps, replacements);
      then replacements;

      else algorithm
        // there is no constant binding -> all others will be replaced by one variable
        (alias_vars, collector) := chooseVariableToKeep(list(BVariable.getVarPointer(cr) for cr in set.simple_variables), var_to_keep);
        vars := VariablePointers.fromList(alias_vars);
        eqs := EquationPointers.fromList(set.simple_equations);
        // causalize the system
        (_, comps) := Causalize.simple(vars, eqs);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          print(StringUtil.headline_3("Variable to keep (values of attributes before replacements):") + BVariable.pointerToString(Pointer.access(var_to_keep))+"\n\n");
        end if;
        // create replacements from strong components
        Replacements.simple(comps, replacements);
        var_lst := VariablePointers.toList(vars);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          print(StringUtil.headline_4("Attribute collector (before replacements): ") + collector.toString(collector) + "\n");
        end if;
        for var in var_lst loop
          rhs := UnorderedMap.getSafe(BVariable.getVarName(var), replacements, sourceInfo());
          eq := Equation.makeAssignment(BVariable.toExpression(var), rhs, Pointer.create(0), NBEquation.TMP_STR, Iterator.EMPTY(), EquationAttributes.default(EquationKind.UNKNOWN, false));
          (solved_eq,_,status, _) := Solve.solveBody(Pointer.access(eq), BVariable.getVarName(Pointer.access(var_to_keep)), FunctionTreeImpl.EMPTY());
          collector := AttributeCollector.fixValues(collector, BVariable.getVarName(var), solved_eq);
        end for;
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          print(StringUtil.headline_4("Attribute collector (after replacements): ") + collector.toString(collector) + "\n");
        end if;
        diffTearingSelect(collector.tearingSelect_map, set);
        stateSelectAlways(collector.stateSelect_map, set);
        checkNominalThreshold(collector.nominal_map, set);
        setNewAttributes(var_to_keep, collector, set);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          print(StringUtil.headline_3("Variable to keep (values of attributes after replacements):") + BVariable.pointerToString(Pointer.access(var_to_keep))+"\n");
        end if;
      then replacements;
    end match;
  end createReplacementRules;

  function setNewAttributes
    "Sets new values for each attribute of kept variable, if possible. "
    input Pointer<Pointer<Variable>> var_to_keep_ptr;
    input AttributeCollector attrcollector;
    input AliasSet set;
  protected
    list<Expression> lst;
    Option<ComponentRef> new_cref;
    Option<Expression> new_min, new_max, new_start;
    Option<StateSelect> new_stateSelect;
    Option<TearingSelect> new_tearingSelect;
    Pointer<Variable> fixed_var, var_to_keep = Pointer.access(var_to_keep_ptr);
    UnorderedMap<ComponentRef, Expression> fixed_start_map;
  algorithm
  // function calls of different set functions in NBVariable.mo
    new_min := getMaximum(attrcollector.min_val_map);
    if Util.isSome(new_min) then
      Pointer.update(var_to_keep, BVariable.setMin(Pointer.access(var_to_keep), new_min, true));
      UnorderedMap.add(BVariable.getVarName(var_to_keep), Util.getOption(new_min), attrcollector.min_val_map); // update attribute collector
    end if;
    new_max := getMinimum(attrcollector.max_val_map);
    if Util.isSome(new_max) then
      Pointer.update(var_to_keep, BVariable.setMax(Pointer.access(var_to_keep), new_max, true));
      UnorderedMap.add(BVariable.getVarName(var_to_keep), Util.getOption(new_max), attrcollector.max_val_map); // update attribute collector
    end if;
    fixed_start_map := setStartFixed(attrcollector.start_map, attrcollector.fixed_map, set);
    if UnorderedMap.size(fixed_start_map) == 1 then
      new_start := SOME(List.first(UnorderedMap.valueList(fixed_start_map)));
      fixed_var := BVariable.getVarPointer(UnorderedMap.firstKey(fixed_start_map));
      BVariable.setFixed(fixed_var, false, true); // avoid having two fixed variables
      UnorderedMap.add(BVariable.getVarName(fixed_var), Expression.BOOLEAN(false), attrcollector.fixed_map); // update attribute collector
      BVariable.setFixed(var_to_keep, overwrite=true);
      UnorderedMap.add(BVariable.getVarName(var_to_keep), Expression.BOOLEAN(true), attrcollector.fixed_map); // update attribute collector
      Pointer.update(var_to_keep, BVariable.setStartAttribute(Pointer.access(var_to_keep), Util.getOption(new_start), true));
      UnorderedMap.add(BVariable.getVarName(var_to_keep), Util.getOption(new_start), attrcollector.start_map); // update attribute collector
    end if;
    (new_cref, new_stateSelect) := chooseStateSelect(attrcollector.stateSelect_map);
    if Util.isSome(new_stateSelect) and Util.isSome(UnorderedMap.get(BVariable.getVarName(var_to_keep),attrcollector.stateSelect_map)) then // only update stateSelect value, if var_to_keep has a stateSelect value
      Pointer.update(var_to_keep, BVariable.setStateSelect(Pointer.access(var_to_keep), Util.getOption(new_stateSelect), true));
      UnorderedMap.add(BVariable.getVarName(var_to_keep), Util.getOption(new_stateSelect), attrcollector.stateSelect_map); // update attribute collector
      if Util.getOption(new_stateSelect) == StateSelect.ALWAYS then // start value of var with StateSelect = always is stronger than start value of fixed var
        new_start := SOME(UnorderedMap.getSafe(Util.getOption(new_cref), attrcollector.start_map, sourceInfo()));
        Pointer.update(var_to_keep, BVariable.setStartAttribute(Pointer.access(var_to_keep), Util.getOption(new_start), true));
        UnorderedMap.add(BVariable.getVarName(var_to_keep), Util.getOption(new_start), attrcollector.start_map); // update attribute collector
      end if;
    end if;
    new_tearingSelect := chooseTearingSelect(attrcollector.tearingSelect_map);
    if Util.isSome(new_tearingSelect) and Util.isSome(UnorderedMap.get(BVariable.getVarName(var_to_keep),attrcollector.tearingSelect_map)) then // only update tearingSelect value, if var_to_keep has a tearingSelect value
      Pointer.update(var_to_keep, BVariable.setTearingSelect(Pointer.access(var_to_keep), Util.getOption(new_tearingSelect), true));
      UnorderedMap.add(BVariable.getVarName(var_to_keep), Util.getOption(new_tearingSelect), attrcollector.tearingSelect_map); // update attribute collector
    end if;
    Pointer.update(var_to_keep_ptr,var_to_keep);
  end setNewAttributes;

  function chooseVariableToKeep
    "choose a variable from a list to keep. returns all variables but the one with the highest rating"
    input list<Pointer<Variable>> var_lst;
    input Pointer<Pointer<Variable>> var_to_keep = Pointer.create(Pointer.create(NBVariable.DUMMY_VARIABLE));
    output list<Pointer<Variable>> acc = {};
    output AttributeCollector attrcollector = ATTRIBUTE_COLLECTOR(
      UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual),
      UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual),
      UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual),
      UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual),
      UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual),
      UnorderedMap.new<StateSelect>(ComponentRef.hash, ComponentRef.isEqual),
      UnorderedMap.new<TearingSelect>(ComponentRef.hash, ComponentRef.isEqual));
  protected
    Pointer<Variable> var;
    Variable cur_var;
    list<Pointer<Variable>> rest;
    Integer cur_rating, max_rating;

  algorithm
    var :: rest := var_lst;
    Pointer.update(var_to_keep, var);
    (max_rating, attrcollector) := rateVar(var, attrcollector);

    for var in rest loop
      (cur_rating, attrcollector) := rateVar(var, attrcollector);
      if cur_rating > max_rating then
        max_rating := cur_rating;
        acc := Pointer.access(var_to_keep) :: acc;
        Pointer.update(var_to_keep, var);
      else
        // do not change anything and just keep the variable and max_rating
        acc := var :: acc;
      end if;
    end for;
  end chooseVariableToKeep;

  function getMaximum
    "Gets the maximum value of an UnorderedMap."
    input UnorderedMap<ComponentRef,Expression> map;
    output Option<Expression> max_exp;
  protected
    list<Expression> constants, rest, lst_values = UnorderedMap.valueList(map);
    Expression max_exp_val;
    Real max_val;
  algorithm
    (constants, rest) := List.splitOnTrue(lst_values, Expression.isConstNumber);
    if not listEmpty(constants) then
      max_val := List.maxElement(list(Expression.realValue(val) for val in constants), realLt);
      rest := Expression.REAL(max_val) :: rest;
    end if;
    if listEmpty(rest) then // constants and rest are empty
      max_exp := NONE();
    elseif List.hasOneElement(rest) then // one constant or one rest
      max_exp := SOME(List.first(rest));
    else
      max_exp_val :=  Expression.CALL(Call.makeTypedCall(
        fn          = NFBuiltinFuncs.MAX_REAL,
        args        = rest,
        variability = NFPrefixes.Variability.PARAMETER,
        purity      = NFPrefixes.Purity.PURE
      ));
      max_exp := SOME(max_exp_val);
    end if;
  end getMaximum;

  function getMinimum
    "Gets the minimum of an UnorderedMap."
    input UnorderedMap<ComponentRef,Expression> map;
    output Option<Expression> min_exp;
  protected
    list<Expression> constants, rest, lst_values = UnorderedMap.valueList(map);
    Expression min_exp_val;
    Real min_val;
  algorithm
    (constants, rest) := List.splitOnTrue(lst_values, Expression.isConstNumber);
    if not listEmpty(constants) then
      min_val := List.minElement(list(Expression.realValue(val) for val in constants), realLt);
      rest := Expression.REAL(min_val) :: rest;
    end if;
    if listEmpty(rest) then // constants and rest are empty
      min_exp := NONE();
    elseif List.hasOneElement(rest) then // one constant or one rest
      min_exp := SOME(List.first(rest));
    else
      min_exp_val :=  Expression.CALL(Call.makeTypedCall(
        fn          = NFBuiltinFuncs.MAX_REAL,
        args        = rest,
        variability = NFPrefixes.Variability.PARAMETER,
        purity      = NFPrefixes.Purity.PURE
      ));
      min_exp := SOME(min_exp_val);
    end if;
  end getMinimum;

  function setStartFixed
    "Analyses start and fixed values." // case 1: 1 or 0 fixed ; case 2: more than 1 fixed
    input UnorderedMap<ComponentRef, Expression> start_map;
    input UnorderedMap<ComponentRef, Expression> fixed_map;
    input AliasSet set;
    output UnorderedMap<ComponentRef, Expression> fixed_start_map = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
  protected
    list<tuple<ComponentRef, Expression>> fixed_lst = UnorderedMap.toList(fixed_map);
    list<Expression> start_lst = UnorderedMap.valueList(start_map);
    list<Expression> fixed_start_lst;
    Integer count_fixed = 0;
    ComponentRef cref;
    Expression sval, fval;
  algorithm
    for tpl in fixed_lst loop
      (cref,fval) := tpl;
      if Expression.isTrue(fval) then
        count_fixed := count_fixed + 1;
        sval := UnorderedMap.getSafe(cref, start_map, sourceInfo());
        UnorderedMap.add(cref, sval, fixed_start_map);
      end if;
    end for;
    if count_fixed == 0 then
      if not List.allEqual(start_lst, Expression.isEqual) then
        if Flags.isSet(Flags.DUMP_REPL) then
          Error.addCompilerWarning(getInstanceName() + ": Alias set with conflicting unfixed start values detected.\n"
                                  + AliasSet.toString(set) + "\n\tStart map after replacements:\n\t" + UnorderedMap.toString(start_map, ComponentRef.toString, Expression.toString,"\n\t"));
        else
          Error.addCompilerWarning(getInstanceName() + ": Alias set with conflicting unfixed start values detected. Use -d=dumprepl for more information.\n");
        end if;
      end if;
    elseif count_fixed > 1 then
      fixed_start_lst := UnorderedMap.valueList(fixed_start_map);
      if not List.allEqual(fixed_start_lst, Expression.isEqual) then
        if Flags.isSet(Flags.DUMP_REPL) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because multiple variables are fixed with different start values!\n" + AliasSet.toString(set)
                           + "\n\tFixed start map after replacements:\n\t" + UnorderedMap.toString(fixed_start_map, ComponentRef.toString, Expression.toString,"\n\t")});
          fail();
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because multiple variables are fixed with different start values! Use -d=dumprepl for more information.\n"});
          fail();
        end if;
      elseif List.allEqual(fixed_start_lst, Expression.isEqual) then
        if Flags.isSet(Flags.DUMP_REPL) then
          Error.addCompilerWarning(getInstanceName() + ": Multiple variables are fixed and have identical start values.\n"
                                  + AliasSet.toString(set) + "\n\tFixed start map after replacements:\n\t" + UnorderedMap.toString(fixed_start_map, ComponentRef.toString, Expression.toString,"\n\t"));
        else
          Error.addCompilerWarning(getInstanceName() + ": Multiple variables are fixed and have identical start values. Use -d=dumprepl for more information.\n");
        end if;
      end if;
    end if;
  end setStartFixed;

  function checkNominalThreshold
    "Calculates quotient of greatest and lowest nominal value and checks if quotient is above the constant NOMINAL_THRESHOLD."
    input UnorderedMap<ComponentRef, Expression> map;
    input AliasSet set;
  protected
    list<Expression> current, lst_values = UnorderedMap.valueList(map);
    array<ExpressionIterator> arr_iter;
    ExpressionIterator iter;
    Expression exp;
    Integer index = 1;
  algorithm
    // if there are no values to compare, return
    if listEmpty(lst_values) then return; end if;

    // all expressions have to be of same size
    if not List.allEqual(list(Type.sizeOf(Expression.typeOf(e)) for e in lst_values), intEq) then
      Error.addCompilerWarning(getInstanceName() + " failed because array nominal values have different size. Use -d=dumprepl for more information.\n");
      fail();
    end if;

    // array handling: create expression iterators and loop while there is a next element
    arr_iter := listArray(list(ExpressionIterator.fromExp(e) for e in lst_values));

    while ExpressionIterator.hasNext(arr_iter[1]) loop
      // get all single expressions and compare
      current := {};
      for i in 1:arrayLength(arr_iter) loop
        (iter, exp) := ExpressionIterator.next(arr_iter[i]);
        arrayUpdate(arr_iter, i, iter);
        current := exp :: current;
      end for;
      // 'current' now represents all values of one array element
      checkNominalThresholdSingle(current, map, set, index);
      index := index + 1;
    end while;
  end checkNominalThreshold;

  function checkNominalThresholdSingle
    "check the nominal of each single value"
    input list<Expression> lst_values;
    input UnorderedMap<ComponentRef, Expression> map;
    input AliasSet set;
    input Integer index;
  protected
    list<Expression> constants, rest, zeroes;
    list<Real> real_constants;
    Real nom_min, nom_max, nom_quotient;
    String str;
  algorithm
    // split by constant and non constant
    (constants, rest) := List.splitOnTrue(lst_values, Expression.isConstNumber);
    // remove and report zeros
    (zeroes, constants) := List.splitOnTrue(constants, Expression.isZero);

    // report non literal nominal values if failtrace is activated
    if Flags.isSet(Flags.FAILTRACE) and not listEmpty(rest) then
      str := getInstanceName() + ": There are non literal nominal values in following alias set:\n"
        + AliasSet.toString(set) + "\n\tNominal map after replacements (conflicting array index = "
        + intString(index) + "):\n\t" + UnorderedMap.toString(map, ComponentRef.toString, Expression.toString,"\n\t");
      Error.addCompilerWarning(str);
    end if;

    // report nominal values that are too far apart
    if not listEmpty(constants) then
      real_constants := list(abs(Expression.realValue(val)) for val in constants);
      nom_min := List.minElement(real_constants, realLt);
      nom_max := List.maxElement(real_constants, realLt);
      nom_quotient := nom_max / nom_min;
      if nom_quotient > NOMINAL_THRESHOLD then
        str := getInstanceName() + ": The quotient of the greatest and lowest nominal value is greater than the nominal threshold = "+ realString(NOMINAL_THRESHOLD) + ".";
        if Flags.isSet(Flags.DUMP_REPL) then
          str := str + "\n" + AliasSet.toString(set) + "\n\tNominal map after replacements (conflicting array index = "
            + intString(index) + "):\n\t" + UnorderedMap.toString(map, ComponentRef.toString, Expression.toString,"\n\t");
        else
          str := str + " Use -d=dumprepl for more information.\n";
        end if;
        Error.addCompilerWarning(str);
      end if;
    end if;

    // zero valued nominal values are not allowed
    if not listEmpty(zeroes) then
      str := getInstanceName() + " failed because zero values are not allowed.";
      if Flags.isSet(Flags.DUMP_REPL) then
        str := str + "\n\tNominal map after replacements (violating array index = " + intString(index) + "):\n\t"
          + UnorderedMap.toString(map, ComponentRef.toString, Expression.toString,"\n\t");
      else
        str := str + " Use -d=dumprepl for more information.\n";
      end if;
      Error.addCompilerError(str);
      fail();
    end if;
  end checkNominalThresholdSingle;

  function stateSelectAlways
    "Throws an error if multiple variables have StateSelect = always."
    input UnorderedMap<ComponentRef, StateSelect> map;
    input AliasSet set;
  protected
    list<StateSelect> lst_values = UnorderedMap.valueList(map);
    Integer count = 0;
  algorithm
    for val in lst_values loop
      if val == StateSelect.ALWAYS then
        count := count + 1;
      end if;
    end for;
    if count > 1 then
      if Flags.isSet(Flags.DUMP_REPL) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because multiple variables have StateSelect = always!\n" + AliasSet.toString(set)
                         + "\n\tStateSelect map after replacements:\n\t" + UnorderedMap.toString(map, ComponentRef.toString, BackendExtension.VariableAttributes.stateSelectString,"\n\t")});
        fail();
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because multiple variables have StateSelect = always! Use -d=dumprepl for more information.\n"});
        fail();
      end if;
    end if;
  end stateSelectAlways;

  function diffTearingSelect
    "Shows a notification if there are different TearingSelect values."
    input UnorderedMap<ComponentRef, TearingSelect> map;
    input AliasSet set;
  protected
    list<TearingSelect> lst_values = UnorderedMap.valueList(map);
    TearingSelect first;
    list<TearingSelect> rest;
    Boolean equal = true;
  algorithm
    if not listEmpty(lst_values) then
      first :: rest := lst_values;
      for val in rest loop
        if first <> val then
          equal := false;
          break;
        end if;
      end for;
      if not equal then
        if Flags.isSet(Flags.DUMP_REPL) then
          Error.addCompilerNotification("There are different TearingSelect values.\n" + AliasSet.toString(set) + "\n\tTearingSelect map after replacements:\n\t"
                                        + UnorderedMap.toString(map, ComponentRef.toString, BackendExtension.VariableAttributes.tearingSelectString,"\n\t"));
        else
          Error.addCompilerNotification("There are different TearingSelect values. Use -d=dumprepl for more information.\n");
        end if;
      end if;
    end if;
  end diffTearingSelect;

  function chooseStateSelect
    "Chooses the StateSelect value with the highest rank among all StateSelect values."
    input UnorderedMap<ComponentRef, StateSelect> map;
    output Option<ComponentRef> chosen_cref;
    output Option<StateSelect> chosen_val;
  protected
    list<tuple<ComponentRef,StateSelect>> lst_values = UnorderedMap.toList(map);
    StateSelect sval, state_select = StateSelect.NEVER;
    ComponentRef compref, cref;
  algorithm
    if listEmpty(lst_values) then
      chosen_val := NONE();
      chosen_cref := NONE();
    elseif List.hasOneElement(lst_values) then
      (compref, sval) := List.first(lst_values);
      chosen_val := SOME(sval);
      chosen_cref := SOME(compref);
    else
      for tpl in lst_values loop
        (cref,sval) := tpl;
        if sval > state_select then
          state_select := sval;
          compref := cref;
        end if;
      end for;
      chosen_val := SOME(state_select);
      chosen_cref := SOME(compref);
    end if;
  end chooseStateSelect;

  function chooseTearingSelect
    "Chooses the TearingSelect value with the highest rank among all TearingSelect values."
    input UnorderedMap<ComponentRef, TearingSelect> map;
    output Option<TearingSelect> chosen_val;
  protected
    list<TearingSelect> lst_values = UnorderedMap.valueList(map);
    TearingSelect tearing_select;
  algorithm
    if listEmpty(lst_values) then
      chosen_val := NONE();
    elseif List.hasOneElement(lst_values) then
      chosen_val := SOME(List.first(lst_values));
    else
      tearing_select := TearingSelect.NEVER;
      for val in lst_values loop
        if val > tearing_select then
          tearing_select := val;
        end if;
      end for;
      chosen_val := SOME(tearing_select);
    end if;
  end chooseTearingSelect;

  function mean // better: geometric mean
    "Calculates the mean of values"
    input list<Expression> lst;
    output Real mean_val;
  protected
    Real cur_sum;
  algorithm
    cur_sum := sum(Expression.realValue(val) for val in lst);
    mean_val := cur_sum / listLength(lst);
    print("Mean = " + String(mean_val));
  end mean;

  function optionMinMax
    "Collects min and max attributes if available."
    input Pointer<Variable> var_ptr;
    input Option<Expression> attr_min, attr_max;
    input output AttributeCollector attrcollector;
  protected
    Expression min_val, max_val;
  algorithm
    if Util.isSome(attr_min) then
      min_val := Util.getOption(attr_min);
      UnorderedMap.add(BVariable.getVarName(var_ptr), min_val, attrcollector.min_val_map);
    end if;
    if Util.isSome(attr_max) then
      max_val := Util.getOption(attr_max);
      UnorderedMap.add(BVariable.getVarName(var_ptr), max_val, attrcollector.max_val_map);
    end if;
  end optionMinMax;

  function optionStartFixed
    "Collects start and fixed attributes if available."
    input Pointer<Variable> var_ptr;
    input Option<Expression> attr_start, attr_fixed;
    input output AttributeCollector attrcollector;
  protected
    Expression start_val, fixed_val;
  algorithm
    if Util.isSome(attr_start) then
      start_val := Util.getOption(attr_start);
      UnorderedMap.add(BVariable.getVarName(var_ptr), start_val, attrcollector.start_map);
    end if;
    if Util.isSome(attr_fixed) then
      fixed_val := Util.getOption(attr_fixed);
      UnorderedMap.add(BVariable.getVarName(var_ptr), fixed_val, attrcollector.fixed_map);
    end if;
  end optionStartFixed;

  function rateVar
    "Rates a variable based on attributes"
    input Pointer<Variable> var_ptr;
    output Integer rating;
    input output AttributeCollector attrcollector;
  protected
    ComponentRef name;
    Expression nominal_val;
    StateSelect stateSelect_val;
    TearingSelect tearingSelect_val;
  algorithm
    if BVariable.isFunctionAlias(var_ptr) or BVariable.isClockAlias(var_ptr) then
      rating := -10000;
    else
      name := BVariable.getVarName(var_ptr);
      rating := -ComponentRef.depth(name);
    end if;

     _ := match Pointer.access(var_ptr)
        local
          Variable var = Pointer.access(var_ptr);
          BackendExtension.VariableAttributes attr;

      case Variable.VARIABLE(backendinfo=BackendExtension.BACKEND_INFO(attributes=attr as BackendExtension.VariableAttributes.VAR_ATTR_REAL())) algorithm
        attrcollector := optionMinMax(var_ptr, attr.min, attr.max, attrcollector);
        attrcollector := optionStartFixed(var_ptr, attr.start, attr.fixed, attrcollector);
        if Util.isSome(attr.nominal) then
          nominal_val := Util.getOption(attr.nominal);
          UnorderedMap.add(BVariable.getVarName(var_ptr), nominal_val, attrcollector.nominal_map);
        end if;
        if Util.isSome(attr.stateSelect) then
          stateSelect_val := Util.getOption(attr.stateSelect);
          if stateSelect_val == StateSelect.ALWAYS then
            rating := rating + 100;
          end if;
          UnorderedMap.add(BVariable.getVarName(var_ptr), stateSelect_val, attrcollector.stateSelect_map);
        end if;
        if Util.isSome(attr.tearingSelect) then
          tearingSelect_val := Util.getOption(attr.tearingSelect);
          UnorderedMap.add(BVariable.getVarName(var_ptr), tearingSelect_val, attrcollector.tearingSelect_map);
        end if;
      then ();

      case Variable.VARIABLE(backendinfo=BackendExtension.BACKEND_INFO(attributes=attr as BackendExtension.VariableAttributes.VAR_ATTR_INT())) algorithm
        attrcollector := optionMinMax(var_ptr, attr.min, attr.max, attrcollector);
        attrcollector := optionStartFixed(var_ptr, attr.start, attr.fixed, attrcollector);
      then ();

      case Variable.VARIABLE(backendinfo=BackendExtension.BACKEND_INFO(attributes=attr as BackendExtension.VariableAttributes.VAR_ATTR_BOOL())) algorithm
        attrcollector := optionStartFixed(var_ptr, attr.start, attr.fixed, attrcollector);
      then ();

      else ();
    end match;
  end rateVar;

  uniontype AttributeCollector
    record ATTRIBUTE_COLLECTOR
      UnorderedMap<ComponentRef,Expression> min_val_map             "set containing all minimum values";
      UnorderedMap<ComponentRef,Expression> max_val_map             "set containing all maximum values";
      UnorderedMap<ComponentRef,Expression> start_map               "set containing all start values";
      UnorderedMap<ComponentRef,Expression> fixed_map               "set containing all fixed values";
      UnorderedMap<ComponentRef,Expression> nominal_map             "set containing all nominal values";
      UnorderedMap<ComponentRef,StateSelect> stateSelect_map        "set containing all stateSelect values";
      UnorderedMap<ComponentRef,TearingSelect> tearingSelect_map    "set containing all tearingSelect values";
    end ATTRIBUTE_COLLECTOR;

    function toString
      "Prints all sets of AttributeCollector"
      input AttributeCollector attrcollector;
      input output String str = "";
    protected
      array<UnorderedMap<ComponentRef,Expression>> array_maps;
      array<String> array_names;
    algorithm
      array_maps := listArray({attrcollector.min_val_map, attrcollector.max_val_map, attrcollector.start_map, attrcollector.fixed_map, attrcollector.nominal_map});
      array_names := listArray({"Min map", "Max map", "Start map", "Fixed map", "Nominal map"});
      for i in 1:arrayLength(array_maps) loop
        if UnorderedMap.isEmpty(array_maps[i]) == false then
          str := str + arrayGet(array_names, i) + ":\n\t"+ UnorderedMap.toString(array_maps[i], ComponentRef.toString, Expression.toString, "\n\t") + "\n";
        end if;
      end for;
      if UnorderedMap.isEmpty(attrcollector.stateSelect_map) == false then
        str := str + "StateSelect map" + ":\n\t"+ UnorderedMap.toString(attrcollector.stateSelect_map, ComponentRef.toString, BackendExtension.VariableAttributes.stateSelectString, "\n\t") + "\n";
      end if;
      if UnorderedMap.isEmpty(attrcollector.tearingSelect_map) == false then
        str := str + "TearingSelect map" + ":\n\t"+ UnorderedMap.toString(attrcollector.tearingSelect_map, ComponentRef.toString, BackendExtension.VariableAttributes.tearingSelectString, "\n\t") + "\n";
      end if;
    end toString;

    function fixValues
      "Adapts min, max and start values of each variable according to the replacements."
      input output AttributeCollector attrcollector;
      input ComponentRef var_cref;
      input Equation solved_eq;
    protected
      UnorderedMap<ComponentRef, Expression> repl = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
      Expression rhs, new_rhs, diff_rhs;
      DifferentiationArguments args;
      Boolean swap_min_max;
      Option<Expression> min_val_opt = UnorderedMap.get(var_cref, attrcollector.min_val_map);
      Option<Expression> max_val_opt = UnorderedMap.get(var_cref, attrcollector.max_val_map);
      Option<Expression> start_opt = UnorderedMap.get(var_cref, attrcollector.start_map);
      Option<Expression> nominal_opt = UnorderedMap.get(var_cref, attrcollector.nominal_map);
      Type ty;
    algorithm
      rhs := Equation.getRHS(solved_eq);
      // min:
      if Util.isSome(min_val_opt) then
        UnorderedMap.add(var_cref, Util.getOption(min_val_opt), repl);
        new_rhs := Expression.map(rhs, function Replacements.applySimpleExp(replacements = repl));
        new_rhs := SimplifyExp.simplify(new_rhs);
        UnorderedMap.add(var_cref, new_rhs, attrcollector.min_val_map);
        min_val_opt := UnorderedMap.get(var_cref, attrcollector.min_val_map);
      end if;

      // max:
      if Util.isSome(max_val_opt) then
        UnorderedMap.add(var_cref, Util.getOption(max_val_opt), repl);
        new_rhs := Expression.map(rhs, function Replacements.applySimpleExp(replacements = repl));
        new_rhs := SimplifyExp.simplify(new_rhs);
        UnorderedMap.add(var_cref, new_rhs, attrcollector.max_val_map);
        max_val_opt := UnorderedMap.get(var_cref, attrcollector.max_val_map);
      end if;

      // if linear factor is negative => swap min and max
      ty := Expression.typeOf(rhs);
      if Type.isContinuous(ty) or Type.isInteger(Type.elementType(ty)) then
        args := Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.SIMPLE);
        args.diffCref := var_cref;
        diff_rhs := Differentiate.differentiateExpression(rhs, args);
        diff_rhs := SimplifyExp.simplify(diff_rhs);
        swap_min_max := Expression.isNegative(diff_rhs);
      else
        swap_min_max := false;
      end if;
      if swap_min_max and Util.isSome(min_val_opt) and Util.isSome(max_val_opt) then
        UnorderedMap.add(var_cref, Util.getOption(max_val_opt), attrcollector.min_val_map);
        UnorderedMap.add(var_cref, Util.getOption(min_val_opt), attrcollector.max_val_map);
      end if;

      // start:
      if Util.isSome(start_opt) then
        UnorderedMap.add(var_cref, Util.getOption(start_opt), repl);
        new_rhs := Expression.map(rhs, function Replacements.applySimpleExp(replacements = repl));
        new_rhs := SimplifyExp.simplify(new_rhs);
        UnorderedMap.add(var_cref, new_rhs, attrcollector.start_map);
      end if;

      // nominal:
      if Util.isSome(nominal_opt) then
        UnorderedMap.add(var_cref, Util.getOption(nominal_opt), repl);
        new_rhs := Expression.map(rhs, function Replacements.applySimpleExp(replacements = repl));
        // normalize the nominal values (remove negations)
        new_rhs := Expression.getNominal(new_rhs);
        UnorderedMap.add(var_cref, new_rhs, attrcollector.nominal_map);
      end if;
    end fixValues;

  end AttributeCollector;

  annotation(__OpenModelica_Interface="backend");
end NBAlias;
