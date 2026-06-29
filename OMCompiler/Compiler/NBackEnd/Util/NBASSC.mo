/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NBASSC
"file:        NBASSC.mo
 package:     NBASSC
 description: This file contains the functions which will perform analytical to structural singularity conversion.
"
public import DAE;
public import ExpressionBasics;
public import ExpressionDump;
public import ExpressionSimplify;

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTreeImpl;
  import NFFunction.Function;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;

  // Backend imports
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.{DifferentiationType, DifferentiationArguments};
  import NBEquation.{Equation, EquationAttributes, EquationKind, EquationPointer, EquationPointers, Iterator};
  import Replacements = NBReplacements;
  import Solve = NBSolve;
  import NBSolve.Status;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VariablePointer, VarData};

  // Util imports
  import UnorderedMap;
  import UnorderedSet;

public
  function main
    "Main function that resolves cyclic alias sets using Bareiss elimination."
    input list<Pointer<Equation>> eqns;
    input list<ComponentRef> vars;
    input Pointer<Integer> index;
    output list<Pointer<Equation>> resolved_eqns = {};
  protected
    array<list<Integer>> indices, values;
    Integer num_crefs, num_eqns, num_nonzero_val;
    array<Integer> op_val1, op_val2, op_val3, op_val4;
    Integer num_op, count_zero_row;
    UnorderedMap<EquationPointer, Expression>  lhs_map;
    array<Expression> lhs_array;
    Boolean singular;
  algorithm
    (indices, values, num_crefs, num_eqns, num_nonzero_val, lhs_map) := buildSparseRepresentation(eqns, vars);
    setMatrix(num_crefs, num_eqns, num_nonzero_val, indices, values);
    (indices, values) := performBareissElimination(indices, values);
    (num_op, op_val1, op_val2, op_val3, op_val4, lhs_array) := applyRecordedOperations(lhs_map);
    // check if the matrix is singular
    (singular, count_zero_row) := checkSingularity(indices, num_eqns);
    if singular then
      tracebackZeroRows(eqns, num_eqns, count_zero_row, num_op, op_val1, op_val2, op_val3, op_val4);
    else
      // create new equations from the transformed matrix
      resolved_eqns := createEquations(vars, index, indices, values, num_eqns, lhs_array);
    end if;
    freeMatrix();
  end main;

  function buildSparseRepresentation
    "Builds the sparse matrix representation from the equation system."
    input list<Pointer<Equation>> eqns;
    input list<ComponentRef> vars;
    output array<list<Integer>> indices, values;
    output Integer num_crefs, num_eqns, num_nonzero_val;
    output UnorderedMap<EquationPointer, Expression>  lhs_map = UnorderedMap.new<Expression>(Equation.hash, Equation.isEqualPtr);
  protected
    Boolean b = true;
    list<ComponentRef> cref_lst;
    Expression res, diff_res, expr;
    DifferentiationArguments args;
    Integer diff_res_int, eqn_index, var_index, var_index1, var_index2;
    Tuple_Id id;
    UnorderedMap<Tuple_Id,Integer> diffs = UnorderedMap.new<Integer>(Tuple_Id.hash, Tuple_Id.isEqual);
    UnorderedSet<EquationPointer> int_eqns = UnorderedSet.new(Equation.hash, Equation.isEqualPtr);
    UnorderedSet<ComponentRef> int_crefs = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedMap<EquationPointer,CrefLst> rows = UnorderedMap.new<CrefLst>(Equation.hash, Equation.isEqualPtr);
    UnorderedMap<ComponentRef, Expression> replacements = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    list<Integer>  lst_enum;
    list<EquationPointer> lst_eqns;
    list<ComponentRef> crefs_rows;
    UnorderedMap<EquationPointer, Integer>  enum_eqns;
    UnorderedMap<ComponentRef, Integer>  enum_crefs;
  algorithm
    for eq_ptr in eqns loop
      // find all crefs of vars in eqn
      cref_lst := Equation.collectCrefs(Pointer.access(eq_ptr), function Equation.collectFromMap(check_map = UnorderedMap.fromLists(vars, vars, ComponentRef.hash, ComponentRef.isEqual)));
      res := Equation.getResidualExp(Pointer.access(eq_ptr));
      args := Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.SIMPLE);
      for cr in cref_lst loop
        args.diffCref := cr;
        // differentiate eqn for cref
        diff_res := SimplifyExp.simplify(Differentiate.differentiateExpression(res, args));
        if Type.isReal(Expression.typeOf(diff_res)) then // if diff is real; check if its an integer of type real
          diff_res_int := realInt(Expression.realValue(diff_res));
          id := TUPLE_ID(eq_ptr, cr);
        elseif Type.isInteger(Expression.typeOf(diff_res)) then // if diff is integer
          diff_res_int := Expression.integerValue(diff_res);
          id := TUPLE_ID(eq_ptr, cr);
          UnorderedMap.add(id, diff_res_int, diffs);
        else
          // eqn is not part of linear system
          b := false;
          break;
        end if;
      end for;
      if b then
        UnorderedSet.add(eq_ptr, int_eqns);
        for cr in cref_lst loop
          UnorderedSet.add(cr, int_crefs);
          UnorderedMap.add(cr, Expression.makeZero(Equation.getType(Pointer.access(eq_ptr))), replacements);
        end for;
        UnorderedMap.add(eq_ptr, cref_lst, rows);
        expr := SimplifyExp.simplify(Expression.map(res, function Replacements.applySimpleExp(replacements = replacements)));
        UnorderedMap.add(eq_ptr, Expression.negate(expr), lhs_map);
      end if;
    end for;
    // enumerate sets
    lst_enum := List.intRange(UnorderedSet.size(int_eqns));
    enum_eqns := UnorderedMap.fromLists(eqns, lst_enum, Equation.hash, Equation.isEqualPtr);
    lst_enum := List.intRange(UnorderedSet.size(int_crefs));
    enum_crefs := UnorderedMap.fromLists(vars, lst_enum, ComponentRef.hash, ComponentRef.isEqual);
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("Variable-to-column mapping:\n"+UnorderedMap.toString(enum_crefs, ComponentRef.toString, intString)+"\n");
    end if;
    indices := arrayCreate(UnorderedSet.size(int_eqns), {});
    values := arrayCreate(UnorderedSet.size(int_eqns), {});
    // create matrix elements for sparse matrix
    lst_eqns := UnorderedSet.toList(int_eqns);
    for eq_ptr in lst_eqns loop
      crefs_rows := UnorderedMap.getSafe(eq_ptr, rows, sourceInfo());
      var_index1 := UnorderedMap.getSafe(listGet(crefs_rows,1), enum_crefs, sourceInfo());
      var_index2 := UnorderedMap.getSafe(listGet(crefs_rows,2), enum_crefs, sourceInfo());
      if var_index1 > var_index2 then
        crefs_rows := listReverse(crefs_rows);
      end if;
      for cr in listReverse(crefs_rows) loop
        eqn_index := UnorderedMap.getSafe(eq_ptr, enum_eqns, sourceInfo());
        var_index := UnorderedMap.getSafe(cr, enum_crefs, sourceInfo());
        indices[eqn_index] := var_index :: indices[eqn_index];
        values[eqn_index] := UnorderedMap.getSafe(TUPLE_ID(eq_ptr,cr), diffs, sourceInfo()) :: values[eqn_index];
      end for;
    end for;
    // determine sparse matrix dimensions
    num_crefs := UnorderedSet.size(int_crefs);
    num_eqns := UnorderedSet.size(int_eqns);
    num_nonzero_val := UnorderedMap.size(diffs);
  end buildSparseRepresentation;

  function performBareissElimination
    "Performs the Bareiss elimination procedure on the system matrix."
    input output array<list<Integer>> indices, values;
  algorithm
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("Sparse matrix before applying the Bareiss algorithm:\n");
      printMatrix();
    end if;
    bareiss();
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("Sparse matrix after applying the Bareiss algorithm:\n");
      printMatrix();
      print("\n");
    end if;
    indices := arrayCreate(arrayLength(indices),{});
    values := arrayCreate(arrayLength(values),{});
    getMatrix(indices,values);
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("List indices:\n");
      for i in 1:arrayLength(indices) loop
        print(List.toString(indices[i], intString) + "\n");
      end for;
      print("\nList values:");
      for i in 1:arrayLength(values) loop
        print(List.toString(values[i], intString) + "\n");
      end for;
      print("\n");
    end if;
  end performBareissElimination;

  function applyRecordedOperations
    "Applies the recorded Bareiss operations to the left-hand side expressions."
    input UnorderedMap<EquationPointer, Expression>  lhs_map;
    output Integer num_op;
    output array<Integer> op_val1, op_val2, op_val3, op_val4;
    output array<Expression> lhs_array;
  protected
    array<Integer> nop, op_modes;
    Integer mode;
  algorithm
    nop := arrayCreate(1,-1);
    num_op := getNumberOfOperations(nop);
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("Number of operations: "+intString(num_op)+"\n");
    end if;
    // allocate operation storage
    op_modes := arrayCreate(num_op,-1);
    op_val1 := arrayCreate(num_op,-1);
    op_val2 := arrayCreate(num_op,-1);
    op_val3 := arrayCreate(num_op,-1);
    op_val4 := arrayCreate(num_op,-1);
    // retrieve all recorded Bareiss operations from the runtime
    getOperations(op_modes, op_val1, op_val2, op_val3, op_val4);
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("All operations:\n");
      print(Array.toString(op_modes, intString)+"\n");
      print(Array.toString(op_val1, intString)+"\n");
      print(Array.toString(op_val2, intString)+"\n");
      print(Array.toString(op_val3, intString)+"\n");
      print(Array.toString(op_val4, intString)+"\n");
    end if;
    // apply operations on left-hand side
    lhs_array := listArray(UnorderedMap.valueList(lhs_map));
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("\nlhs array: "+Array.toString(lhs_array, Expression.toString)+"\n");
    end if;
    for i in 1:num_op loop
      mode := op_modes[i];
      if Flags.isSet(Flags.DUMP_ASSC) then
        print("current op_mode: "+intString(mode)+"\n");
      end if;
      _:= match mode
        local
          Expression tmp_val, tmp_val1, tmp_val2;
          Integer gcd;
        case 0 algorithm // mode for pivot-update operation
          tmp_val1 := Expression.MULTARY(
              arguments = {Expression.makeInteger(op_val2[i]), lhs_array[op_val3[i]+1]},
              inv_arguments = {},
              operator = Operator.makeMul(Type.REAL()));
          tmp_val1:= SimplifyExp.simplify(tmp_val1);
          tmp_val2 := Expression.MULTARY(
              arguments = {Expression.makeInteger(op_val4[i]), lhs_array[op_val1[i]+1]},
              inv_arguments = {},
              operator = Operator.makeMul(Type.REAL()));
          tmp_val2:= SimplifyExp.simplify(tmp_val2);
          lhs_array[op_val3[i]+1]:= Expression.MULTARY(
              arguments = {tmp_val1},
              inv_arguments = {tmp_val2},
              operator = Operator.makeAdd(Type.REAL()));
          lhs_array[op_val3[i]+1] := SimplifyExp.simplify(lhs_array[op_val3[i]+1]);
          if Flags.isSet(Flags.DUMP_ASSC) then
            print("case 0, updated lhs_array: "+Array.toString(lhs_array, Expression.toString)+"\n");
          end if;
        then lhs_array;
        case 1 algorithm // mode for swap-rows operation
          tmp_val := lhs_array[op_val1[i]+1];
          lhs_array[op_val1[i]+1] := lhs_array[op_val2[i]+1];
          lhs_array[op_val2[i]+1] := tmp_val;
          if Flags.isSet(Flags.DUMP_ASSC) then
            print("case 1, updated lhs_array: "+Array.toString(lhs_array, Expression.toString)+"\n");
          end if;
        then lhs_array;
        case 2 algorithm // mode for gcd operation
          gcd := op_val2[i];
          lhs_array[op_val1[i]+1] := Expression.MULTARY(
              arguments = {lhs_array[op_val1[i]+1]},
              inv_arguments = {Expression.makeInteger(gcd)},
              operator = Operator.makeMul(Type.REAL()));
          lhs_array[op_val1[i]+1] := SimplifyExp.simplify(lhs_array[op_val1[i]+1]);
          if Flags.isSet(Flags.DUMP_ASSC) then
            print("case 2, updated lhs_array: "+Array.toString(lhs_array, Expression.toString)+"\n");
          end if;
        then lhs_array;
        else lhs_array;
      end match;
    end for;
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("final lhs_array: "+Array.toString(lhs_array, Expression.toString)+"\n\n");
    end if;
  end applyRecordedOperations;

  function checkSingularity
    "Detects singular matrices by checking for zero rows."
    input array<list<Integer>> indices;
    input Integer num_eqns;
    output Boolean singular = false;
    output Integer count_zero_row = 0;
  algorithm
    for i in 1:num_eqns loop
      if listLength(indices[i]) == 0 then
        count_zero_row := count_zero_row + 1;
      end if;
    end for;
    if count_zero_row > 0 then
      singular := true;
    end if;
  end checkSingularity;

  function tracebackZeroRows
    "Reconstructs the sequence of operations that produced each zero row."
    input list<Pointer<Equation>> eqns;
    input Integer num_eqns, count_zero_row, num_op;
    input array<Integer> op_val1, op_val2, op_val3, op_val4;
  protected
    list<Integer> traceback;
    list<list<Integer>> all_tracebacks;
    Integer current_eq, count = 0;
    DAE.Exp exp_dae, exp_dae_elem;
    String eq_str, str_all = "";
    list<Integer> factors_pivot, factors_update;
  algorithm
    // ToDo: switch to new simplify
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("Number of zero rows: "+intString(count_zero_row)+"\n");
    end if;
    all_tracebacks := {};
    for zero_row in 1:count_zero_row loop // each zero_row
      traceback := {};
      factors_pivot := {};
      factors_update := {};
      current_eq := num_eqns - count_zero_row;
      traceback := current_eq :: traceback;
      for op in num_op:-1:1 loop // each operation backwards
        if op_val3[op] == current_eq then
          traceback := op_val1[op] :: traceback;
          factors_pivot := op_val2[op] :: factors_pivot;
          factors_update := op_val4[op] :: factors_update;
          current_eq := op_val1[op];
        end if;
      end for;
      if Flags.isSet(Flags.DUMP_ASSC) then
        print("Involved equations: " + List.toString(traceback, intString)+"\n");
        print("Factors pivot: " + List.toString(factors_pivot, intString)+"\n");
        print("Factors update: " + List.toString(factors_update, intString)+"\n");
      end if;
      all_tracebacks := traceback :: all_tracebacks;
    end for;
    count := 1;
    // trace back how each zero row was created
    for traceback in all_tracebacks loop
      exp_dae := DAE.CREF(DAE.CREF_IDENT("("+intString(listGet(traceback,1))+")", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT);
      if Flags.isSet(Flags.DUMP_ASSC) then
        print("Step-by-step construction of the zero row:\n");
      end if;
      eq_str :=  "("+intString(listGet(traceback,1))+"): " + Expression.toString(Util.getOption(Equation.getLHS(Pointer.access(listGet(eqns,1))))) + " = " + Expression.toString(Util.getOption(Equation.getRHS(Pointer.access(listGet(eqns,1))))) + "\n";
      for eq in 2:listLength(traceback) loop
        exp_dae_elem := DAE.CREF(DAE.CREF_IDENT("("+intString(listGet(traceback,eq))+")", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT);
        exp_dae := DAE.BINARY(DAE.BINARY(DAE.ICONST(listGet(factors_pivot, eq-1)), DAE.MUL(DAE.T_REAL_DEFAULT), exp_dae_elem),
                              DAE.SUB(DAE.T_REAL_DEFAULT),
                              DAE.BINARY(DAE.ICONST(listGet(factors_update, eq-1)), DAE.MUL(DAE.T_REAL_DEFAULT), exp_dae));
        if Flags.isSet(Flags.DUMP_ASSC) then
          print(ExpressionBasics.printExpStr(exp_dae)+"\n");
        end if;
        eq_str :=  eq_str + "("+intString(listGet(traceback,eq))+"): " + Expression.toString(Util.getOption(Equation.getLHS(Pointer.access(listGet(eqns,eq))))) + " = " + Expression.toString(Util.getOption(Equation.getRHS(Pointer.access(listGet(eqns,eq))))) + "\n";
      end for;
      // all calculations with corresponding equations in one string
      (exp_dae, _) := ExpressionSimplify.simplify(exp_dae);
      if Flags.isSet(Flags.DUMP_ASSC) then
          print("after simplify "+ExpressionBasics.printExpStr(exp_dae)+"\n");
      end if;
      str_all := str_all + "The zero row in ("+ intString(num_eqns-count) +") was produced by the following calculation: " + ExpressionBasics.printExpStr(exp_dae) + " with \n" + eq_str + "\n";
      count := count + 1;
    end for;
    if Flags.isSet(Flags.DUMP_ASSC) then
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because sparse matrix is singular.\n" + str_all});
      fail();
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because sparse matrix is singular, for more information please use -d=dumpASSC.\n"});
      fail();
    end if;
  end tracebackZeroRows;

  function createEquations
    "Creates new equations according to the replacements and resolves cyclic alias equations."
    input list<ComponentRef> vars;
    input Pointer<Integer> index;
    input array<list<Integer>> indices, values;
    input Integer num_eqns;
    input array<Expression> lhs_array;
    output list<Pointer<Equation>> resolved_eqns = {};
  protected
    Pointer<Equation> new_eq;
    Expression cref_exp, sub_exp, rhs, lhs;
    list<Integer> indices_list, values_list;
    Status status;
    Equation solved_eq;
  algorithm
    // iterate backwards due to upper-triangular dependency structure of the system
    for i in num_eqns:-1:1 loop
      rhs := Expression.makeInteger(0);
      for j in 1:listLength(indices[i]) loop
        indices_list := indices[i];
        cref_exp := Expression.fromCref(listGet(vars,listGet(indices_list, j)+1)); // indices are 0-based, Modelica lists are 1-based
        values_list := values[i];
        sub_exp := Expression.MULTARY(
            arguments = {cref_exp, Expression.makeInteger(listGet(values_list, j))},
            inv_arguments = {},
            operator = Operator.makeMul(Type.REAL()));
        sub_exp := SimplifyExp.simplify(sub_exp);
        rhs := Expression.MULTARY(
            arguments = {rhs, sub_exp},
            inv_arguments = {},
            operator = Operator.makeAdd(Expression.typeOf(sub_exp)));
      end for;
      rhs := SimplifyExp.simplify(rhs);
      if Flags.isSet(Flags.DUMP_ASSC) then
        print("rhs: "+Expression.toString(rhs)+"\n");
      end if;
      new_eq := Equation.makeAssignment(rhs, lhs_array[i], index, NBEquation.TMP_STR, Iterator.EMPTY(), EquationAttributes.default(EquationKind.UNKNOWN, false));
      if Flags.isSet(Flags.DUMP_ASSC) then
        print("new_eq: "+Equation.toString(Pointer.access(new_eq))+"\n");
      end if;
      // solve equation for variable to eliminate cyclic dependencies
      (solved_eq,status, _) := Solve.solveBody(Pointer.access(new_eq), listGet(vars,i), UnorderedMap.new<Function>(AbsynUtil.pathHash, AbsynUtil.pathEqual));
      if Flags.isSet(Flags.DUMP_ASSC) then
        print("solved_eq: "+Equation.toString(solved_eq)+"\n");
      end if;
      resolved_eqns := Pointer.create(solved_eq) :: resolved_eqns;
    end for;
    if Flags.isSet(Flags.DUMP_ASSC) then
      print("Number of equations: "+intString(listLength(resolved_eqns))+"\n");
      for eq_ptr in resolved_eqns loop
        print("eq_ptr: "+Equation.toString(Pointer.access(eq_ptr))+"\n");
      end for;
    end if;
  end createEquations;

  function setMatrix
    input Integer nv                "number of variables";
    input Integer ne                "number of equations";
    input Integer nz                "number of nonzero values";
    input array<list<Integer>> adj  "adjacency matrix";
    input array<list<Integer>> val  "value matrix";
    external "C" ASSC_setMatrix(nv,ne,nz,adj,val) annotation(Library = "omcruntime");
  end setMatrix;

  function getMatrix
    input array<list<Integer>> adj  "adjacency matrix";
    input array<list<Integer>> val  "value matrix";
    external "C" ASSC_getMatrix(adj,val) annotation(Library = "omcruntime");
  end getMatrix;

  function freeMatrix
    external "C" ASSC_freeMatrix() annotation(Library = "omcruntime");
  end freeMatrix;

  function printMatrix
    external "C" ASSC_printMatrix() annotation(Library = "omcruntime");
  end printMatrix;

  function bareiss
    external "C" ASSC_bareiss() annotation(Library = "omcruntime");
  end bareiss;

  function getNumberOfOperations
    input array<Integer> nop /* always size 1 */;
    output Integer num;
    external "C" num=ASSC_getNumberOfOperations(nop) annotation(Library = "omcruntime");
  end getNumberOfOperations;

  function getOperations
    input array<Integer> op_modes;
    input array<Integer> op_val1;
    input array<Integer> op_val2;
    input array<Integer> op_val3;
    input array<Integer> op_val4;
    external "C" ASSC_getOperations(op_modes, op_val1, op_val2, op_val3, op_val4) annotation(Library = "omcruntime");
  end getOperations;

protected
  type CrefLst = list<ComponentRef>;

  uniontype Tuple_Id
    "tuple as key for UnorderedMap"
    record TUPLE_ID
      Pointer<Equation> eq_ptr;
      ComponentRef cref;
    end TUPLE_ID;

    function toString
      input Tuple_Id id;
      output String str;
    algorithm
      str := Equation.toString(Pointer.access(id.eq_ptr));
      str := BVariable.toString(BVariable.getVar(id.cref, sourceInfo())) + str;
    end toString;

    function hash
      "just hashes the id based on its string representation"
      input Tuple_Id id;
      output Integer hash;
    algorithm
      hash := stringHashDjb2(toString(id));
    end hash;

    function isEqual
      input Tuple_Id id1;
      input Tuple_Id id2;
      output Boolean b;
    algorithm
      b := Equation.isEqualPtr(id1.eq_ptr, id2.eq_ptr) and ComponentRef.isEqual(id1.cref, id2.cref);
    end isEqual;
  end Tuple_Id;

  annotation(__OpenModelica_Interface="nbackend");
end NBASSC;