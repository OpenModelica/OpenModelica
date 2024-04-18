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
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import Variable = NFVariable;
  import NFPrefixes.Variability;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Causalize = NBCausalize;
  import NBEquation.{Equation, EquationPointers, EqData};
  import Replacements = NBReplacements;
  import Solve = NBSolve;
  import StrongComponent = NBStrongComponent;
  import NBVariable.{VariablePointers, VarData};

  // Util imports
  import MetaModelica.Dangerous;
  import StringUtil;
  import UnorderedMap;
  import UnorderedSet;
public
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
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
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
          (replacements, newEquations) := aliasCausalize(varData.unknowns, eqData.simulation);

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

          // remove alias vars from all relevant arrays after splitting off non trivial alias vars
          varData.variables   := VariablePointers.removeList(alias_vars, varData.variables);
          varData.unknowns    := VariablePointers.removeList(alias_vars, varData.unknowns);
          varData.algebraics  := VariablePointers.removeList(alias_vars, varData.algebraics);
          varData.states      := VariablePointers.removeList(alias_vars, varData.states);
          varData.discretes   := VariablePointers.removeList(alias_vars, varData.discretes);
          varData.initials    := VariablePointers.removeList(alias_vars, varData.initials);

          // categorize alias vars and sort them to the correct arrays
          (non_trivial_alias, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasNonTrivialAliasBinding);

          // split off constant alias
          // update constant start values and add to parameters
          // otherwise they would not show in the result file
          (const_vars, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasConstOrParamAliasBinding);
          const_vars := list(BVariable.setVarKind(var, BackendExtension.VariableKind.PARAMETER()) for var in const_vars);
          const_vars := list(BVariable.setBindingAsStartAndFix(var) for var in const_vars);
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
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end aliasDefault;

  function aliasCausalize
    "STEPS:
      1. collect alias sets (variables, equations, optional constant binding)
      2. balance sets - choose variable to keep if necessary
      3. match/sort set (linear w.r.t. since all equations contain two unknown crefs at max and are simple/linear)
    "
    input VariablePointers variables;
    input EquationPointers equations;
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
      print(StringUtil.headline_2("[dumprepl] Alias Sets:") + "\n");
      if listEmpty(sets) then
        print("<No Alias Sets>\n\n");
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
          if listLength(set1.simple_equations) > listLength(set2.simple_equations) then
            set.simple_equations := Pointer.create(eq) :: Dangerous.listAppendDestroy(set2.simple_equations, set1.simple_equations);
          else
            set.simple_equations := Pointer.create(eq) :: Dangerous.listAppendDestroy(set1.simple_equations, set2.simple_equations);
          end if;

          // try to change as few pointer entries as possible
          if listLength(set1.simple_variables) > listLength(set2.simple_variables) then
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

        // fail for multidimensional crefs and record elements for now
        case Expression.CREF()
          guard(BVariable.size(BVariable.getVarPointer(exp.cref)) > 1 or Util.isSome(BVariable.getParent(BVariable.getVarPointer(exp.cref))))
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
    "creates replacement rules from a simple set by causalizing it and replacing the expressions in order"
    input AliasSet set;
    input output UnorderedMap<ComponentRef, Expression> replacements;
  algorithm
    // ToDo: fix variable attributes to keep
    // report errors/warnings
    replacements := match set.const_opt
      local
        Pointer<Equation> const_eq;
        list<Pointer<Variable>> alias_vars;
        VariablePointers vars;
        EquationPointers eqs;
        list<StrongComponent> comps;

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
        alias_vars := chooseVariableToKeep(list(BVariable.getVarPointer(cr) for cr in set.simple_variables));
        vars := VariablePointers.fromList(alias_vars);
        eqs := EquationPointers.fromList(set.simple_equations);
        // causalize the system
        (_, comps) := Causalize.simple(vars, eqs);
        // create replacements from strong components
        Replacements.simple(comps, replacements);
      then replacements;
    end match;
  end createReplacementRules;

  function chooseVariableToKeep
    "choose a variable from a list to keep. returns all variables but the one with the highest rating"
    input list<Pointer<Variable>> tail;
    input Pointer<Pointer<Variable>> var_to_keep = Pointer.create(Pointer.create(NBVariable.DUMMY_VARIABLE));
    input Integer max_rating = -1;
    output list<Pointer<Variable>> acc;
  algorithm
    acc := match tail
      local
        list<Pointer<Variable>> rest;
        Pointer<Variable> var, new_alias;
        Integer cur_rating, new_max_rating;

      case var :: rest guard(max_rating == -1) algorithm
        // this is the entry point. update the variable to keep with the very first of the list
        Pointer.update(var_to_keep, var);
        new_max_rating := rateVar(var);
      then chooseVariableToKeep(rest, var_to_keep, new_max_rating);

      case var :: rest algorithm
        // check if new rating is better than old
        cur_rating := rateVar(var);
        if cur_rating > max_rating then
          // put the currently held variable back to the list and update the new "variable to keep"
          new_alias := Pointer.access(var_to_keep);
          Pointer.update(var_to_keep, var);
          new_max_rating := cur_rating;
        else
          // do not change anything and just keep the variable and max_rating
          new_alias := var;
          new_max_rating := max_rating;
        end if;
      then new_alias :: chooseVariableToKeep(rest, var_to_keep, new_max_rating);

      else {};
    end match;
  end chooseVariableToKeep;

  function rateVar
    "Rates a variable based on attributes"
    input Pointer<Variable> var_ptr;
    output Integer rating;
  algorithm
    // ToDo: put acutal rating algorithm here
    rating := if BVariable.isFixed(var_ptr) then 1 else 0;
    rating := if BVariable.isFunctionAlias(var_ptr) then rating - 5 else rating;
  end rateVar;

  annotation(__OpenModelica_Interface="backend");
end NBAlias;
