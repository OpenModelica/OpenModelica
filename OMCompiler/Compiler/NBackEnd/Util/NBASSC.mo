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

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;

  // Backend imports
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.{DifferentiationType, DifferentiationArguments};
  import NBEquation.{Equation, EquationPointers};
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VariablePointer, VarData};

public
  function main
    input list<Pointer<Equation>> eqns;
    input list<ComponentRef> vars;
  protected
    array<list<Integer>> indices, values;
    Boolean b = true;
    list<ComponentRef> cref_lst;
    Expression res, diff_res;
    DifferentiationArguments args;
    Integer diff_res_int;
    Tuple_Id id;
    UnorderedMap<Tuple_Id,Integer> diffs = UnorderedMap.new<Integer>(Tuple_Id.hash, Tuple_Id.isEqual);
    UnorderedSet<Pointer<Equation>> int_eqns = UnorderedSet.new(Equation.hash, Equation.isEqual);
    UnorderedSet<list<ComponentRef>> int_crefs;// = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedMap<Pointer<Equation>,list<ComponentRef>> rows = UnorderedMap.new<ParameterList>(Equation.hash, Equation.isEqual);
  algorithm
    // ### pseudo code of what shall happen
    // for eqn in eqns:
    //   b = true
    //   crefs = find all crefs of vars in eqn
    //   for cref in crefs
    //      diff = differentiate eqn for cref
    //      simplify diff
    //      if diff is integer
    //          save (eqn, cref) -> diff to map (diffs)
    //      else
    //          eqn is not part of linear system (b=false)
    //          break
    //      end if
    //    end for
    //    if b then
    //      save eqn to set (int_eqns)
    //      save crefs to set (int_crefs)
    //      save eqn -> crefs in map (rows)
    //    end if
    //  end for
    //
    //  enumerate sets int_eqns and int_crefs
    //  initialize indices[] and values[] of size |int_eqns|
    //
    //  for eqn in int_eqns
    //    for cref in rows(eqn)
    //      eqn_index = get index of equation eqn in int_eqns
    //      var_index = get index of variable cref in int_crefs
    //      indices[eqn_index] += append var_index
    //      values[eqn_index] += append diffs(eqn,cref)
    //    end for
    //  end for

    //diffs := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
    for eq_ptr in eqns loop
      cref_lst := Equation.collectCrefs(Pointer.access(eq_ptr), function Equation.collectFromMap(check_map = UnorderedMap.fromLists(vars, vars, ComponentRef.hash, ComponentRef.isEqual)));
      for cref in cref_lst loop
        print("cref "+BVariable.toString(BVariable.getVar(cref, sourceInfo()))+"\n");
      end for;
      res := Equation.getResidualExp(Pointer.access(eq_ptr));
      print("here2 "+Expression.toString(res)+"\n" );
      args := Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.SIMPLE);

      for cr in cref_lst loop
        print("here3"+BVariable.toString(BVariable.getVar(cr, sourceInfo()))+"\n");
        args.diffCref := cr;
        diff_res := SimplifyExp.simplify(Differentiate.differentiateExpression(res, args));
        print("here5"+Expression.toString(diff_res)+"\n" );
        print(Type.toString(Expression.typeOf(diff_res))+"\n");
        if Type.isReal(Expression.typeOf(diff_res)) then // if diff is real
          diff_res_int := realInt(Expression.realValue(diff_res));
          print("from Real "+intString(diff_res_int)+"\n");
          id := TUPLE_ID(eq_ptr, cr);
          UnorderedMap.add(id, diff_res_int, diffs);
        elseif Type.isInteger(Expression.typeOf(diff_res)) then // if diff is integer
          diff_res_int := Expression.integerValue(diff_res);
          print("from Int "+intString(diff_res_int)+"\n");
          id := TUPLE_ID(eq_ptr, cr);
          UnorderedMap.add(id, diff_res_int, diffs);
        else
          b := false;
          break;
        end if;
      end for;
      if b then
        UnorderedSet.add(eq_ptr, int_eqns);
        UnorderedSet.add(cref_lst, int_crefs);
        UnorderedMap.add(eq_ptr, cref_lst, rows);
      end if;
    end for;

    // enumerate ...
    indices := arrayCreate(UnorderedSet.size(int_eqns), {});
    values := arrayCreate(UnorderedSet.size(int_eqns), {});


    // remove this dummy section
    // ################################
    indices := arrayCreate(3, {});
    values := arrayCreate(3, {});
    indices[1] := {1,2};
    values[1] := {10,2};
    indices[2] := {1};
    values[2] := {5};
    indices[3] := {1,3};
    values[3] := {8,-2};
    // ################################


    setMatrix(3,3,5,indices,values);
    for cref in vars loop
      print("cref "+BVariable.toString(BVariable.getVar(cref, sourceInfo()))+"\n");
    end for;
    for eq in eqns loop
      print("eq "+ Equation.toString(Pointer.access(eq))+"\n");
    end for;
    printMatrix();
    freeMatrix();
  end main;

  function setMatrix
    input Integer nv                "number of variables";
    input Integer ne                "number of equations";
    input Integer nz                "number of nonzero values";
    input array<list<Integer>> adj  "adjacency matrix";
    input array<list<Integer>> val  "value matrix";
    external "C" ASSC_setMatrix(nv,ne,nz,adj,val) annotation(Library = "omcruntime");
  end setMatrix;

  function freeMatrix
    external "C" ASSC_freeMatrix() annotation(Library = "omcruntime");
  end freeMatrix;

  function printMatrix
    external "C" ASSC_printMatrix() annotation(Library = "omcruntime");
  end printMatrix;

protected
  type ParameterList = list<ComponentRef>;

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
      //str := if not Iterator.isEmpty(id.iter) then " [" + Iterator.toString(id.iter) + "]" else "";
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