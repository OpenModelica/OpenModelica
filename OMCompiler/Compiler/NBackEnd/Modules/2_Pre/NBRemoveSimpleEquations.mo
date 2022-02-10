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
encapsulated package NBRemoveSimpleEquations
"file:        NBRemoveSimpleEquations.mo
 package:     NBRemoveSimpleEquations
 description: This file contains the functions for the remove simple equations
              module.
"

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

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Causalize = NBCausalize;
  import NBEquation.{Equation, EquationPointers};
  import Replacements = NBReplacements;
  import Solve = NBSolve;
  import StrongComponent = NBStrongComponent;
  import NBVariable.VariablePointers;

  // Util imports
  import MetaModelica.Dangerous;
  import StringUtil;
  import UnorderedMap;
  import UnorderedSet;
public
  function main
    "Wrapper function for any detect states function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
  protected
    Module.removeSimpleEquationsInterface func;
  algorithm
    (func) := getModule();

    bdae := match bdae
      local
        BVariable.VarData varData         "Data containing variable pointers";
        BEquation.EqData eqData           "Data containing equation pointers";

      case BackendDAE.MAIN(varData = varData, eqData = eqData)
        algorithm
          (varData, eqData) := func(varData, eqData);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case BackendDAE.JACOBIAN(varData = varData, eqData = eqData)
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
    output Module.removeSimpleEquationsInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS)
  algorithm
    func := match flag
      case "default" then removeSimpleEquationsDefault;
      /* ... New remove simple equations modules have to be added here */
      else fail();
    end match;
  end getModule;

protected
  uniontype SimpleSet "gets accumulated to find sets of simple equations and solve them"
    record SIMPLE_SET
      list<ComponentRef> simple_variables         "list of all variables in this set";
      list<Pointer<Equation>> simple_equations    "list of all equations in this set";
      Option<Pointer<Equation>> const_opt         "optional constant binding of one variable";
    end SIMPLE_SET;

    function toString
      input SimpleSet set;
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
  end SimpleSet;

  constant SimpleSet EMPTY_SIMPLE_SET = SIMPLE_SET({}, {}, NONE());

  // needed for unordered map
  type SetPtr = Pointer<SimpleSet>;

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

  function removeSimpleEquationsDefault
    "STEPS:
      1. collect alias sets (variables, equations, optional constant binding)
      2. balance sets - choose variable to keep if necessary
      3. match/sort set (linear w.r.t. unknowns since all equations contain two crefs at max and are simple/linear)
      4. apply replacements
      5. save replacements in bindings of alias variables
    "
    extends Module.removeSimpleEquationsInterface;
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
          (replacements, newEquations) := removeSimpleEquationsCausalize(varData.unknowns, eqData.simulation);

          // -----------------------------------
          // 4. apply replacements
          // 5. save replacements in bindings of alias variables
          // -----------------------------------
          (eqData, varData) := Replacements.applySimple(eqData, varData, replacements);
          alias_vars := list(BVariable.getVarPointer(cref) for cref in UnorderedMap.keyList(replacements));

          // save new equations and compress affected arrays(some might have been removed)
          eqData.simulation := EquationPointers.compress(newEquations);
          eqData.equations := EquationPointers.compress(eqData.equations);
          eqData.continuous := EquationPointers.compress(eqData.continuous);

          // remove alias vars from all relevant arrays after splitting off non trivial alias vars
          varData.variables := VariablePointers.removeList(alias_vars, varData.variables);
          varData.unknowns := VariablePointers.removeList(alias_vars, varData.unknowns);
          varData.algebraics := VariablePointers.removeList(alias_vars, varData.algebraics);
          varData.states := VariablePointers.removeList(alias_vars, varData.states);
          varData.discretes := VariablePointers.removeList(alias_vars, varData.discretes);
          varData.initials := VariablePointers.removeList(alias_vars, varData.initials);

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
          non_trivial_eqs := list(Equation.generateBindingEquation(var, eqData.uniqueIndex) for var in non_trivial_alias);
          eqData.removed := EquationPointers.addList(non_trivial_eqs, eqData.removed);
          //eqData.equations := EquationPointers.addList(non_trivial_eqs, eqData.equations);

          // if we replaced variables by constants it is possible that new simple equations formed
          if not listEmpty(const_vars) then
            (varData, eqData) := removeSimpleEquationsDefault(varData, eqData);
          end if;
      then (varData, eqData);

      case (BVariable.VAR_DATA_JAC(), BEquation.EQ_DATA_JAC())
        algorithm
          // -----------------------------------
          //            1. 2. 3.
          // apply only on temporary equations,
          // result equations cannot be removed!
          // -----------------------------------
          (replacements, newEquations) := removeSimpleEquationsCausalize(varData.unknowns, eqData.temporary);

          // -----------------------------------
          // 4. apply replacements
          // 5. save replacements in bindings of alias variables
          // -----------------------------------
          (eqData, varData) := Replacements.applySimple(eqData, varData, replacements);
          alias_vars := list(BVariable.getVarPointer(cref) for cref in UnorderedMap.keyList(replacements));

          // save new equations and compress affected arrays(some might have been removed)
          eqData.temporary := EquationPointers.compress(newEquations);
          eqData.equations := EquationPointers.compress(eqData.equations);

          // remove alias vars from all relevant arrays
          varData.variables := VariablePointers.removeList(alias_vars, varData.variables);
          varData.unknowns := VariablePointers.removeList(alias_vars, varData.unknowns);

          // categorize alias vars and sort them to the correct arrays
          // discard constants entirely for jacobians
          (_, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasConstBinding);
          (non_trivial_alias, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasNonTrivialAliasBinding);

          varData.aliasVars := VariablePointers.addList(alias_vars, varData.aliasVars);
          varData.knowns := VariablePointers.addList(non_trivial_alias, varData.knowns);

          // add non trivial alias to removed
          non_trivial_eqs := list(Equation.generateBindingEquation(var, eqData.uniqueIndex) for var in non_trivial_alias);
          eqData.removed := EquationPointers.addList(non_trivial_eqs, eqData.removed);
          eqData.equations := EquationPointers.addList(non_trivial_eqs, eqData.equations);
      then (varData, eqData);

      case (BVariable.VAR_DATA_HES(), BEquation.EQ_DATA_HES())
        algorithm
          // -----------------------------------
          //            1. 2. 3.
          // apply only on temporary equations,
          // result equation cannot be removed!
          // -----------------------------------
          (replacements, newEquations) := removeSimpleEquationsCausalize(varData.unknowns, eqData.temporary);

          // -----------------------------------
          // 4. apply replacements
          // 5. save replacements in bindings of alias variables
          // -----------------------------------
          (eqData, varData) := Replacements.applySimple(eqData, varData, replacements);
          alias_vars := list(BVariable.getVarPointer(cref) for cref in UnorderedMap.keyList(replacements));

          // save new equations and compress affected arrays(some might have been removed)
          eqData.temporary := EquationPointers.compress(newEquations);
          eqData.equations := EquationPointers.compress(eqData.equations);

          // remove alias vars from all relevant arrays
          varData.variables := VariablePointers.removeList(alias_vars, varData.variables);
          varData.unknowns := VariablePointers.removeList(alias_vars, varData.unknowns);

          // categorize alias vars and sort them to the correct arrays
          // discard constants entirely for jacobians and hessians
          (_, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasConstBinding);
          (non_trivial_alias, alias_vars) := List.splitOnTrue(alias_vars, BVariable.hasNonTrivialAliasBinding);

          varData.aliasVars := VariablePointers.addList(alias_vars, varData.aliasVars);
          varData.knowns := VariablePointers.addList(non_trivial_alias, varData.knowns);

          // add non trivial alias to removed
          non_trivial_eqs := list(Equation.generateBindingEquation(var, eqData.uniqueIndex) for var in non_trivial_alias);
          eqData.removed := EquationPointers.addList(non_trivial_eqs, eqData.removed);
          eqData.equations := EquationPointers.addList(non_trivial_eqs, eqData.equations);
      then (varData, eqData);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end removeSimpleEquationsDefault;

  function removeSimpleEquationsCausalize
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
    list<SimpleSet> sets;
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
          print(StringUtil.headline_4("Alias Set " + intString(setIdx) + ":") + SimpleSet.toString(set) + "\n");
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
  end removeSimpleEquationsCausalize;

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

      case BEquation.SIMPLE_EQUATION() algorithm
        crefTpl := findCrefs(Expression.fromCref(eq.rhs), crefTpl);
        crefTpl := findCrefs(Expression.fromCref(eq.lhs), crefTpl);
      then crefTpl;

      case BEquation.SCALAR_EQUATION() guard(isSimple(eq.lhs) and isSimple(eq.rhs)) algorithm
        crefTpl := Expression.fold(eq.rhs, findCrefs, crefTpl);
        crefTpl := Expression.fold(eq.lhs, findCrefs, crefTpl);
      then crefTpl;

      // ToDo: ARRAY_EQUATION RECORD_EQUATION (AUX_EQUATION?)
      else crefTpl;
    end match;

    (map, delete) := match crefTpl
      local
        SetPtr set_ptr, set1_ptr, set2_ptr;
        SimpleSet set, set1, set2;
        ComponentRef cr1, cr2;

      // one variable is connected to a parameter or constant
      case CREF_TPL(cr_lst = {cr1}) algorithm
        if not UnorderedMap.contains(cr1, map) then
          // the variable does not belong to a set -> create new one
          set := EMPTY_SIMPLE_SET;
          set.simple_variables := {cr1};
          set.const_opt := SOME(Pointer.create(eq));
          UnorderedMap.add(cr1, Pointer.create(set), map);
        else
          // it already belongs to a set, try to update it and throw error if there already is a const binding
          set_ptr := UnorderedMap.getSafe(cr1, map);
          set := Pointer.access(set_ptr);
          if isSome(set.const_opt) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to add Equation:\n"
              + Equation.toString(eq) + "\n because the set already contains a constant binding.
              Overdetermined Set!:" + SimpleSet.toString(set)});
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
          set1_ptr := UnorderedMap.getSafe(cr1, map);
          set2_ptr := UnorderedMap.getSafe(cr2, map);
          set1 := Pointer.access(set1_ptr);
          set2 := Pointer.access(set2_ptr);
          set := EMPTY_SIMPLE_SET;

          if referenceEq(set1_ptr, set2_ptr) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to merge following sets " +
                "because they would create a loop. This would create an underdetermined Set!:\n\n" +
                "Trying to merge: " + Equation.toString(eq) + "\n\n" +
                SimpleSet.toString(set1) + "\n" + SimpleSet.toString(set2)});
            fail();
          elseif (isSome(set1.const_opt) and isSome(set2.const_opt)) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to merge following sets " +
                "because both have a constant binding. This would create an overdetermined Set!:\n\n" +
                SimpleSet.toString(set1) + "\n" + SimpleSet.toString(set2)});
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
          set_ptr := UnorderedMap.getSafe(cr1, map);
          set := Pointer.access(set_ptr);
          // add cr2 to variables and add new equation pointer
          set.simple_variables := cr2 :: set.simple_variables;
          set.simple_equations := Pointer.create(eq) :: set.simple_equations;
          Pointer.update(set_ptr, set);
          // add new hash entry for c2
          UnorderedMap.add(cr2, set_ptr, map);
        elseif UnorderedMap.contains(cr2, map) then
          // Update set
          set_ptr := UnorderedMap.getSafe(cr2, map);
          set := Pointer.access(set_ptr);
          // add cr1 to variables and add new equation pointer
          set.simple_variables := cr1 :: set.simple_variables;
          set.simple_equations := Pointer.create(eq) :: set.simple_equations;
          Pointer.update(set_ptr, set);
          // add new hash entry for c1
          UnorderedMap.add(cr1, set_ptr, map);
        else
          // create new set
          set := EMPTY_SIMPLE_SET;
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
  looks for variable crefs in Expressions, if more then 2 are found stop searching
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

  function isSimple
    "BB start module for detecting simple equation/expressions"
    input Expression exp;
    output Boolean isSimple;
  algorithm
     //print("Traverse "  + ExpressionDump.printExpStr(inExp) + "\n");
    isSimple := Expression.fold(exp, checkOperator, true);
    //print("Simple: " +  boolString(outIsSimple) + "\n");
  end isSimple;

  function checkOperator "BB
  check, if left and right expression of an equation are simple:
  a = b, a = -b, a = not b, a = 2.0, etc.
  this module will be extended in the future!
  "
    input Expression exp;
    input output Boolean simple;
  protected
    function checkOp
      "BB"
      input Operator op;
      output Boolean b;
    algorithm
      b := match(op)
        case Operator.OPERATOR(op = NFOperator.Op.ADD)        then true;
        case Operator.OPERATOR(op = NFOperator.Op.SUB)        then true;
        case Operator.OPERATOR(op = NFOperator.Op.UMINUS)     then true;
        case Operator.OPERATOR(op = NFOperator.Op.NOT)        then true;
                                                              else false;
      end match;
    end checkOp;
  algorithm
    // only check if not previously already found to not be simple
    if simple then
      simple := match(exp)
        case Expression.MULTARY() then checkOp(exp.operator);
        case Expression.BINARY()  then checkOp(exp.operator);
        case Expression.UNARY()   then checkOp(exp.operator);
        case Expression.LUNARY()  then checkOp(exp.operator);
        case Expression.CREF()    then true;
        case Expression.INTEGER() then true;
        case Expression.REAL()    then true;
        case Expression.BOOLEAN() then true;
        case Expression.STRING()  then true;
                                  else false;
      end match;
    end if;
  end checkOperator;

  function getSimpleSets
    "extracts all simple sets from the hashTable and avoids duplicates by marking variables"
    input UnorderedMap<ComponentRef, SetPtr> map;
    input Integer size;
    output list<SimpleSet> sets = {};
  protected
    UnorderedSet<ComponentRef> cref_marks = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, size);
    list<tuple<ComponentRef, SetPtr>> entry_lst;
    ComponentRef simple_cref;
    SetPtr set_ptr;
    SimpleSet set;
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
    input SimpleSet set;
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
        comps := Causalize.simple(vars, eqs);
        // create replacements from strong components
        Replacements.simple(comps, replacements);
      then replacements;

      else algorithm
        // there is no constant binding -> all others will be replaced by one variable
        alias_vars := chooseVariableToKeep(list(BVariable.getVarPointer(cr) for cr in set.simple_variables));
        vars := VariablePointers.fromList(alias_vars);
        eqs := EquationPointers.fromList(set.simple_equations);
        // causalize the system
        comps := Causalize.simple(vars, eqs);
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
  end rateVar;

  annotation(__OpenModelica_Interface="backend");
end NBRemoveSimpleEquations;
