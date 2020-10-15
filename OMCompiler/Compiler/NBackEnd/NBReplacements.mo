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
encapsulated uniontype NBReplacements
"file:        NBReplacements.mo
 package:     NBReplacements
 description:
  Replacements consists of a mapping between variables and expressions, the first binary tree of this type.
  To eliminate a variable from an equation system a replacement rule varname->expression is added to this
  datatype.
  To be able to update these replacement rules incrementally a backward lookup mechanism is also required.
  For instance, having a rule a->b and adding a rule b->c requires to find the first rule a->b and update it to
  a->c. This is what the second binary tree is used for.
"

protected
  // rename self import
  import Replacements = NBReplacements;

  // NF imports
  import Binding = NFBinding;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import FunctionTreeImpl = NFFlatten.FunctionTreeImpl;
  import HashSet = NFHashSet;
  import HashTableCrToExp = NFHashTableCrToExp;
  import HashTableCrToLst = NFHashTable3;
  import Variable = NFVariable;

  // Backend imports
  import BVariable = NBVariable;
  import EqData = NBEquation.EqData;
  import Equation = NBEquation.Equation;
  import EquationPointers = NBEquation.EquationPointers;
  import HashTableCrToCrEqLst = NBHashTableCrToCrEqLst;
  import Solve = NBSolve;
  import StrongComponent = NBStrongComponent;
  import VarData = NBVariable.VarData;
  import VariablePointers = NBVariable.VariablePointers;

  // Util imports
  import BaseHashTable;

public

  record REPLACEMENTS
    HashTableCrToExp.HashTable hashTable        "src -> dst, used for replacing. src is variable, dst is expression.";
    HashTableCrToLst.HashTable invHashTable     "dst -> list of sources. dst is a variable, sources are variables.";
  end REPLACEMENTS;

  function single
    "performs a single replacement"
    input output Expression exp   "Replacement happens inside this expression";
    input Expression old          "Replaced by new";
    input Expression new          "Replaces old";
  algorithm
    exp := Expression.map(exp, function singleTraverse(old = old, new = new));
  end single;

  function singleTraverse
    input output Expression exp   "Replacement happens inside this expression";
    input Expression old          "Replaced by new";
    input Expression new          "Replaces old";
  algorithm
    exp := if Expression.isEqual(exp, old) then new else exp;
  end singleTraverse;

  function simple
    "creates simple replacement rules for removeSimpleEquations"
    input list<StrongComponent> comps;
    input output HashTableCrToExp.HashTable replacements;
  algorithm
    replacements := List.fold(comps, addSimple, replacements);
  end simple;

  function addSimple
    "ToDo: More cases!"
    input StrongComponent comp;
    input output HashTableCrToExp.HashTable replacements;
  algorithm
    replacements := match comp
      local
        ComponentRef varName;
        Equation solvedEq;
        Boolean solved;
        Expression replace_exp;

      case StrongComponent.SINGLE_EQUATION() algorithm
        // solve the equation for the variable
        varName := BVariable.getVarName(comp.var);
        (solvedEq, _, solved) := Solve.solve(Pointer.access(comp.eqn), varName, FunctionTreeImpl.EMPTY());
        if solved then
          // apply all previous replacements on the RHS
          replace_exp := Equation.getRHS(solvedEq);
          replace_exp := applySimpleExp(replace_exp, replacements);
          // add the new replacement rule
          replacements := BaseHashTable.add((varName, replace_exp), replacements);
        else
          fail();
        end if;
      then replacements;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong component is not simple: " + StrongComponent.toString(comp)});
      then fail();
    end match;
  end addSimple;

  function applySimple
    "Used for RemoveSimpleEquations.
    This should be applied before partitioning. Otherwise all systems have to be checked for jacobians
    and hessians on which this also has to be applied. Can be applied on single jacobians and hessians
    while removing simple equations on them."
    input output EqData eqData;
    input output VarData varData; // bindings
    input HashTableCrToExp.HashTable replacements "rules for replacements are stored inside here";
  protected
    list<tuple<ComponentRef, Expression>> entries;
    ComponentRef aliasCref;
    Expression replacement;
    Pointer<Variable> var_ptr;
    Variable var;
  algorithm
    eqData := match eqData
      case EqData.EQ_DATA_SIM() algorithm
        // we do not want to traverse removed equations, otherwise we could break them
        eqData.simulation   := EquationPointers.mapExp(eqData.simulation, function applySimpleExp(replacements = replacements));
        eqData.continuous   := EquationPointers.mapExp(eqData.continuous, function applySimpleExp(replacements = replacements));
        eqData.discretes    := EquationPointers.mapExp(eqData.discretes, function applySimpleExp(replacements = replacements));
        eqData.initials     := EquationPointers.mapExp(eqData.initials, function applySimpleExp(replacements = replacements));
        eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, function applySimpleExp(replacements = replacements));
      then eqData;

      case EqData.EQ_DATA_JAC() algorithm
        eqData.results      := EquationPointers.mapExp(eqData.results, function applySimpleExp(replacements = replacements));
        eqData.temporary    := EquationPointers.mapExp(eqData.temporary, function applySimpleExp(replacements = replacements));
        eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, function applySimpleExp(replacements = replacements));
      then eqData;

      case EqData.EQ_DATA_HES() algorithm
        Pointer.update(eqData.result, Equation.map(Pointer.access(eqData.result), function applySimpleExp(replacements = replacements)));
        eqData.temporary    := EquationPointers.mapExp(eqData.temporary, function applySimpleExp(replacements = replacements));
        eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, function applySimpleExp(replacements = replacements));
      then eqData;
    end match;

    // apply on bindings (is this necessary?)
    varData := match varData
      case VarData.VAR_DATA_SIM() algorithm
        varData.variables := VariablePointers.map(varData.variables, function applySimpleVar(replacements = replacements));
      then varData;
      case VarData.VAR_DATA_JAC() algorithm
        varData.variables := VariablePointers.map(varData.variables, function applySimpleVar(replacements = replacements));
      then varData;
      case VarData.VAR_DATA_HES() algorithm
        varData.variables := VariablePointers.map(varData.variables, function applySimpleVar(replacements = replacements));
      then varData;
    end match;

    // update alias variable bindings
    entries := BaseHashTable.hashTableList(replacements);
    for entry in entries loop
      (aliasCref, replacement) := entry;
      var_ptr := BVariable.getVarPointer(aliasCref);
      var := Pointer.access(var_ptr);
      var.binding := Binding.update(var.binding, replacement);
      Pointer.update(var_ptr, var);
    end for;
  end applySimple;

  function applySimpleExp
    "Needs to be mapped with Expression.map()"
    input output Expression exp                   "Replacement happens inside this expression";
    input HashTableCrToExp.HashTable replacements "rules for replacements are stored inside here";
  algorithm
    exp := match exp
      case Expression.CREF() guard(BaseHashTable.hasKey(exp.cref, replacements)) algorithm
      then BaseHashTable.get(exp.cref, replacements);
      else exp;
    end match;
  end applySimpleExp;

  function applySimpleVar
    "applys replacement on the variable binding expression"
    input output Variable var;
    input HashTableCrToExp.HashTable replacements "rules for replacements are stored inside here";
  algorithm
    var := match var
      local
        Binding binding;
      case Variable.VARIABLE(binding = binding as Binding.TYPED_BINDING()) algorithm
        binding.bindingExp := Expression.map(binding.bindingExp, function applySimpleExp(replacements = replacements));
        var.binding := binding;
      then var;
      else var;
    end match;
  end applySimpleVar;

  function simpleToString
    input HashTableCrToExp.HashTable replacements;
    output String str = "";
  protected
    list<tuple<ComponentRef, Expression>> entries;
    ComponentRef key;
    Expression value;
  algorithm
    str := StringUtil.headline_2("[dumprepl] Replacements: " + str);
    entries := BaseHashTable.hashTableList(replacements);
    for entry in entries loop
      (key, value) := entry;
      str := str + "\t" + ComponentRef.toString(key) + "\t ==> \t" + Expression.toString(value) + "\n";
    end for;
  end simpleToString;

/*

  function empty
    "Returns an empty set of replacement rules"
    input Integer size = BaseHashTable.defaultBucketSize;
    input Boolean simple = false;
    output Replacements variableReplacements;
  protected
    HashTableCrToExp.HashTable replacements;
    HashTableCrToCrEqLst.HashTable groups;
  algorithm
    // ToDo: remove all those sized calls, they are just duplicate functions
    replacements := HashTableCrToExp.emptyHashTableSized(size);
    groups := HashTableCrToCrEqLst.emptyHashTableSized(size);
    variableReplacements := SIMPLE_REPLACEMENTS(replacements, groups);
  end empty;

  function add
    input output Replacements replacements;
    input Expression src                    "for simple replacements src and dst are not yet determined";
    input Expression dst;
    input Equation eqn;
  algorithm
    // new (a -> b), existing (b -> c)
    // new (a -> b), existing (a -> c) (FAIL or REPLACE?)
    // new (a -> b), existing (c -> a) (how to detect for f(.., a, ...)?)
    replacements := match replacements
      case SIMPLE_REPLACEMENTS() algorithm
      then replacements;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed adding replacement for expressions: "
        + "\n\t 1. " + Expression.toString(src) + "\n\t 2. " + Expression.toString(dst) + "\n In equation: \n\t"
        + Equation.toString(eqn)});
      then fail();
    end match;
  end add;

  function addStatic
    input output Replacements repl;
    input ComponentRef src;
    input Expression dst;
    input Equation eqn;
  algorithm
    repl := match repl
      case SIMPLE_REPLACEMENTS() guard(not BaseHashTable.hasKey(src, repl.replacements)) algorithm
        repl.replacements := BaseHashTable.add((src, dst), repl.replacements);
      then repl;

      // need forward replacement

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed adding replacement for componentRef: "
        + "\n\t - " + ComponentRef.toString(src) + "\n In equation: \n\t" + Equation.toString(eqn)});
      then fail();
    end match;

  end addStatic;

  function empty
    "Returns an empty set of replacement rules"
    output Replacements variableReplacements;
    input Integer size = BaseHashTable.defaultBucketSize;
  protected
    HashTableCrToExp.HashTable hashTable;
    HashTableCrToLst.HashTable invHashTable;
  algorithm
    // ToDo: remove all those sized calls, they are just duplicate functions
    hashTable := HashTableCrToExp.emptyHashTableSized(size);
    invHashTable := HashTableCrToLst.emptyHashTableSized(size);
    variableReplacements := REPLACEMENTS(hashTable, invHashTable);
  end empty;

  function add
    input output Replacements replacements;
    input ComponentRef src;
    input Expression dst;
  algorithm
    // new (a -> b), existing (b -> c)
    // new (a -> b), existing (a -> c) (FAIL or REPLACE?)
    // new (a -> b), existing (c -> a) (how to detect for f(.., a, ...)?)
    if BaseHashTable.hasKey(src, replacements.hashTable) then
      // fail if there is already a replacement rule for this expression
      fail();
    else
      //replacements := makeTransitiveBackwards(replacements, src, dst);
      replacements.hashTable := BaseHashTable.add((src, dst), replacements.hashTable);
    end if;
    //replacements.invHashTable := BaseHashTable.add((src, dst), replacements.invHashTable);

  end add;

  function addList
    input output Replacements replacements;
    input list<tuple<ComponentRef, Expression>> tpl_lst;
  protected
    ComponentRef src;
    Expression dst;
  algorithm
    for tpl in tpl_lst loop
      (src, dst) := tpl;
      replacements := add(replacements, src, dst);
    end for;
  end addList;

  public function add
    "Adds a replacement rule to the set of replacement rules given as argument.
    If a replacement rule a->b already exists and we add a new rule b->c then
    the rule a->b is updated to a->c. This is done using the make_transitive
    function."
    input Replacements replacements;
    input ComponentRef src;
    input Expression dst;
    //input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
    output Replacements outRepl;
  algorithm
    outRepl:= match (repl,inSrc,inDst,inFuncTypeExpExpToBooleanOption)
      local
        DAE.ComponentRef src,src_1;
        DAE.Exp dst,dst_1;
        HashTable2.HashTable ht,ht_1,eht,eht_1;
        HashTable3.HashTable invHt,invHt_1;
        list<DAE.Ident> iv;
        String s;
        Option<HashTable2.HashTable> derConst;

      case ((repl as REPLACEMENTS(ht,invHt)),src,dst)
        algorithm
          olddst = BaseHashTable.get(src, ht) "if rule a->b exists, fail";
       then fail();

      case (_,src,dst,_)
        equation
          (REPLACEMENTS(ht,invHt,eht,iv,derConst),src_1,dst_1) = makeTransitive(repl, src, dst, inFuncTypeExpExpToBooleanOption);
          ht_1 = BaseHashTable.add((src_1, dst_1),ht);
          invHt_1 = addReplacementInv(invHt, src_1, dst_1);
          eht_1 = addExtendReplacement(eht,src_1,NONE());
        then
          REPLACEMENTS(ht_1,invHt_1,eht_1,iv,derConst);
      case (_,_,_,_)
        equation
          s = ComponentReference.printComponentRefStr(inSrc);
          print("-BackendVarTransform.addReplacement failed for " + s);
        then
          fail();
    end match;
  end add;

  function remove
    "removes the replacement for a given key using BaseHashTable.delete
    the extendhashSet is not updated"
    input Replacements replacements   "replacements object";
    input ComponentRef src                    "cref to remove";
  algorithm
    _ := match replacements
      local
        Expression dst;
        HashTableCrToExp.HashTable hashTable;
        HashTableCrToLst.HashTable invHashTable;
      case REPLACEMENTS(hashTable = hashTable, invHashTable = invHashTable)
        algorithm
          if BaseHashTable.hasKey(src, hashTable) then
            dst := BaseHashTable.get(src, hashTable);
            BaseHashTable.delete(src, hashTable);
            removeInv(invHashTable, dst);
          end if;
      then ();

      else algorithm
        Error.addInternalError(getInstanceName() + " failed for " + ComponentRef.toString(src) +"\n", sourceInfo());
      then fail();
    end match;
  end remove;

  function removeList
    input Replacements replacements "replacements object";
    input list<ComponentRef> src_lst        "cref list to remove";
  algorithm
    for src in src_lst loop
      remove(replacements, src);
    end for;
  end removeList;

protected
  function removeInv
    "Helper function to remove
    removes the inverse rule of a replacement in the second binary tree
    of Replacements."
    input HashTableCrToLst.HashTable invHashTable;
    input Expression dst;
  algorithm
    for exp in Expression.extract(dst, Expression.isCref) loop
      BaseHashTable.delete(Expression.toCref(exp), invHashTable);
    end for;
  end removeInv;
*/

  annotation(__OpenModelica_Interface="backend");
end NBReplacements;
