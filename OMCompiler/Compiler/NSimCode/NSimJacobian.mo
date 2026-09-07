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

encapsulated package NSimJacobian
"file:        NSimJacobian.mo
 package:     NSimJacobian
 description: This file contains the functions for creating simcode jaobians and sparsity patterns.
"

public
  // NF imports
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Subscript = NFSubscript;
  import Type = NFType;

  // Backend imports
  import Adjacency = NBAdjacency;
  import NBAdjacency.Dependency;
  import BackendDAE = NBackendDAE;
  import NBEquation.{Equation, Iterator, EquationPointer, EquationPointers, EqData};
  import BEquation = NBEquation;
  import NBVariable.{VariablePointers, VarData};
  import BVariable = NBVariable;
  import Variable = NFVariable;
  import Jacobian = NBJacobian;
  import Partition = NBPartition;

  // SimCode imports
  import SimCodeUtil = NSimCodeUtil;
  import SimCode = NSimCode;
  import SimGenericCall = NSimGenericCall;
  import NSimCode.Identifier;
  import SimStrongComponent = NSimStrongComponent;
  import NSimVar.{SimVar, SimVars, VarType, ConvertMemo};

  // Old SimCode imports
  import OldSimCode = SimCode;
  import OldBackendDAE = BackendDAE;

  // Util imports
  import StringUtil;

  uniontype SparsityRow
    record SPARSITY_ROW
      ComponentRef equation_name "only for debugging";
      list<SimGenericCall.SimIterator> equation_iterators;
      list<tuple<ComponentRef, Dependency, Boolean /*true=repeated*/>> dependencies;
      list<ComponentRef> solved_crefs;
    end SPARSITY_ROW;

    function create
      input ComponentRef equation_name;
      input Iterator equation_iterator;
      input UnorderedMap<ComponentRef, Dependency> dependencies;
      input UnorderedSet<ComponentRef> repetitions;
      input list<ComponentRef> solved_crefs;
      output SparsityRow row;
    protected
      list<ComponentRef> crefs;
      list<Dependency> deps;
      list<Boolean> reps;
    algorithm
      crefs := UnorderedMap.keyList(dependencies);
      deps  := UnorderedMap.valueList(dependencies);
      reps  := list(UnorderedSet.contains(cref, repetitions) for cref in crefs);

      // add whole subscripts for code gen purposes
      crefs := list(ComponentRef.fillSubscripts(cref) for cref in crefs);

      row := SPARSITY_ROW(
        equation_name       = equation_name,
        equation_iterators  = SimGenericCall.SimIterator.fromIterator(equation_iterator),
        dependencies        = list((cref, dep, rep) threaded for cref in crefs, dep in deps, rep in reps),
        solved_crefs        = list(ComponentRef.fillSubscripts(cref) for cref in solved_crefs));
    end create;

    function convert
      input SparsityRow row;
      output OldSimCode.SparsityRow oldrow;
    algorithm
      oldrow := OldSimCode.SPARSITY_ROW(
        equation_name       = ComponentRef.toDAE(row.equation_name),
        equation_iterators  = list(SimGenericCall.SimIterator.convert(iter) for iter in row.equation_iterators),
        dependencies        = list((ComponentRef.toDAE(Util.tuple31(tpl)), Dependency.convert(Util.tuple32(tpl)), Util.tuple33(tpl)) for tpl in row.dependencies),
        solved_crefs        = list(ComponentRef.toDAE(cref) for cref in row.solved_crefs)
      );
    end convert;

    function toString
      input SparsityRow row;
      output String str;
      function dependencyString
        input tuple<ComponentRef, Dependency, Boolean> tpl;
        output String str = "(" + ComponentRef.toString(Util.tuple31(tpl)) + ", " + Dependency.toString(Util.tuple32(tpl)) + ", " + boolString(Util.tuple33(tpl)) + ")";
      end dependencyString;
    algorithm
      str := ComponentRef.toString(row.equation_name) + " ... " + List.toString(row.solved_crefs, ComponentRef.toString) + " ... " + List.toString(row.dependencies, dependencyString);
    end toString;

    function mergeDuplicateRows
      "Index reduction can occasionally produce more residual equations than
      there are physical Jacobian rows (numberOfResultVars, the runtime's
      fixed row capacity) -- e.g. static_IR.mos, where an over-determined
      algebraic subsystem yields several equivalent constraints that all end
      up tagged with the same solved_crefs. In that situation resizable
      Jacobian codegen (CodegenC.tpl) would still assign each extra equation
      its own incrementing row index, writing past the runtime's
      numberOfResultVars-sized buffers.
      This is NOT the same as a legitimately coupled multi-row system (e.g.
      algebraicLoop.mos), where several genuinely different equations validly
      share the same solved_crefs set (one row each, all coupled to the same
      variables) with row count already matching numberOfResultVars -- such
      cases must be left untouched, hence the row-count guard below."
      input list<SparsityRow> rows_in;
      input Integer numberOfResultVars;
      output list<SparsityRow> rows_out;
    protected
      UnorderedMap<String, SparsityRow> row_map;
      list<String> order;
      String key;
      SparsityRow existing, merged;
    algorithm
      if listLength(rows_in) <= numberOfResultVars then
        rows_out := rows_in;
      else
        row_map := UnorderedMap.new<SparsityRow>(stringHashDjb2, stringEq);
        order := {};
        for row in rows_in loop
          key := stringDelimitList(list(ComponentRef.toString(c) for c in row.solved_crefs), ",");
          if UnorderedMap.contains(key, row_map) then
            existing := UnorderedMap.getSafe(key, row_map, sourceInfo());
            merged := existing;
            merged.dependencies := List.unionOnTrue(existing.dependencies, row.dependencies, dependencyCrefEqual);
            UnorderedMap.add(key, merged, row_map);
          else
            UnorderedMap.add(key, row, row_map);
            order := key :: order;
          end if;
        end for;
        order := listReverse(order);
        rows_out := list(UnorderedMap.getSafe(k, row_map, sourceInfo()) for k in order);
      end if;
    end mergeDuplicateRows;

    function dependencyCrefEqual
      input tuple<ComponentRef, Dependency, Boolean> dep1;
      input tuple<ComponentRef, Dependency, Boolean> dep2;
      output Boolean b;
    algorithm
      b := ComponentRef.isEqual(Util.tuple31(dep1), Util.tuple31(dep2));
    end dependencyCrefEqual;
  end SparsityRow;

  uniontype Sparsity
    record SPARSITY
      list<SparsityRow> rows;
    end SPARSITY;

    record EMPTY
    end EMPTY;

    function create
      input Adjacency.Matrix mat;
      input Integer numberOfResultVars;
      output Sparsity sparsity;
    algorithm
      sparsity := match mat
        case Adjacency.SPARSITY() then SPARSITY(SparsityRow.mergeDuplicateRows(
          list(SparsityRow.create(e, i, d, r, s) threaded for e in mat.equation_names, i in mat.equation_iterators, d in mat.dependencies, r in mat.repetitions, s in mat.solved_crefs),
          numberOfResultVars));
        case Adjacency.EMPTY() then EMPTY();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " can only handle sparsity or empty matrices but got:\n" + Adjacency.Matrix.toString(mat)});
        then fail();
      end match;
    end create;

    function convert
      input Sparsity sparsity;
      output OldSimCode.Sparsity oldsparsity;
    algorithm
      oldsparsity := match sparsity
        case SPARSITY() then OldSimCode.SPARSITY(list(SparsityRow.convert(row) for row in sparsity.rows));
        case EMPTY() then OldSimCode.EMPTY();
      end match;
    end convert;

    function toString
      input Sparsity sparsity;
      output String str = StringUtil.headline_3("Resizable Sparsity Pattern");
    algorithm
      str := match sparsity
        case SPARSITY() then str + List.toString(sparsity.rows, SparsityRow.toString, List.Style.NEWLINE) + "\n";
        else str + " -- EMPTY -- \n";
      end match;
    end toString;
  end Sparsity;

  uniontype SimJacobian
    record SIM_JAC
      String name                                         "unique matrix name";
      Integer jacobianIndex                               "unique jacobian index";
      Integer partitionIndex                              "index of partition it belongs to";
      Integer numberOfResultVars                          "corresponds to the number of rows";
      list<SimStrongComponent.Block> columnEqns           "column equations equals in size to column vars";
      list<SimStrongComponent.Block> constantEqns         "List of constant equations independent of seed variables";
      list<SimVar> columnVars                             "all column vars, none results vars index -1, the other corresponding to rows index";
      list<SimVar> seedVars                               "corresponds to the number of columns";
      Sparsity sparsityMatrix                             "new sparsity pattern";
      list<SimGenericCall> generic_loop_calls             "Generic for-loop and array calls";
      Option<UnorderedMap<ComponentRef, SimVar>> jac_map  "hash table for cref -> simVar";
      Boolean isAdjoint                                   "indicates if this is an adjoint jacobian";
      Boolean isBidirectional                              "indicates if this jacobian is part of a bidirectional pair";
      Integer adjointJacobianIndex                         "index of the adjoint jacobian for bidirectional (-1 if not bidirectional)";
      String adjointMatrixName                              "matrix name of the adjoint jacobian for bidirectional";
    end SIM_JAC;

    function toString
      input SimJacobian simJac;
      output String str = "";
    algorithm
      str := match simJac
        case SIM_JAC() algorithm
          if isEmpty(simJac) then
            str := StringUtil.headline_2("[EMPTY] SimCode Jacobian " + simJac.name + "(idx = " + intString(simJac.jacobianIndex) + ", partition = " + intString(simJac.partitionIndex) + ")") + "\n";
          else
            str := StringUtil.headline_2("SimCode Jacobian " + simJac.name + "(idx = " + intString(simJac.jacobianIndex) + ", partition = " + intString(simJac.jacobianIndex) + ")") + "\n";
            str := str + StringUtil.headline_4("SeedVars (size = " + intString(listLength(simJac.seedVars)) + ")");
            for var in simJac.seedVars loop
              str := str + SimVar.toString(var, "  ") + "\n";
            end for;
            str := str + "\n" + StringUtil.headline_4("TmpVars (size = " + intString(listLength(simJac.columnVars)) + ")");
            for var in simJac.columnVars loop
              str := str + SimVar.toString(var, "  ") + "\n";
            end for;
            // TODO: print list of ResultVars
            str := str + "\n" + StringUtil.headline_4("ResultVars (size = " + intString(simJac.numberOfResultVars) + ")");

            // TODO: count equations properly, e.g. linear systems are falsely counted as a single equation
            str := str + "\n" + StringUtil.headline_3("Column Equations (size = " + intString(listLength(simJac.columnEqns)) + ")");
            for eq in simJac.columnEqns loop
              str := str + SimStrongComponent.Block.toString(eq, "  ");
            end for;
            if not listEmpty(simJac.constantEqns) then
              str := str + StringUtil.headline_3("Constant Equations");
              for eq in simJac.constantEqns loop
                str := str + SimStrongComponent.Block.toString(eq, "  ");
              end for;
            end if;
            str := str + "\n" + Sparsity.toString(simJac.sparsityMatrix);

            if not listEmpty(simJac.generic_loop_calls) then
              str := str + StringUtil.headline_3("Generic Calls");
              str := str + List.toString(simJac.generic_loop_calls, SimGenericCall.toString, List.Style.NEWLINE_INDENT);
            end if;
            str := str + "\n";
          end if;
        then str;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end toString;

    function isEmpty
      input SimJacobian simJac;
      output Boolean b;
    algorithm
      b := match simJac
        case SIM_JAC() then simJac.numberOfResultVars == 0;
        else false;
      end match;
    end isEmpty;

/*
    function fromSystems
      input list<System.System> partitions;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
    protected
      list<BackendDAE> jacobians = {};
    algorithm
      for partition in partitions loop
        if isSome(partition.jacobian) then
          jacobians := Util.getOption(partition.jacobian) :: jacobians;
        end if;
      end for;

      if listEmpty(jacobians) then
        simJacobian := NONE();
      else
        (simJacobian, indices) := create(Jacobian.combine(jacobians, "A"), indices);
      end if;
    end fromSystems;

    function fromSystemsSparsity
      input list<System.System> partitions;
      input output Option<SimJacobian> simJacobian;
      input UnorderedMap<ComponentRef, SimVar> sim_map;
      input output SimCode.SimCodeIndices indices;
    algorithm
      (simJacobian, indices) := match (partitions, simJacobian)
        local
          BackendDAE jacobian;

        case (_, NONE())                                      then (NONE(), indices);
        case ({System.SYSTEM(jacobian = NONE())}, _)          then (NONE(), indices);
        case ({System.SYSTEM(jacobian = SOME(jacobian))}, _)  then createSparsity(jacobian, Util.getOption(simJacobian), sim_map, indices);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed! Partitioned partitions are not yet supported by this function."});
        then fail();

      end match;
    end fromSystemsSparsity;
*/
    function create
      input BackendDAE jacobian;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    algorithm
      simJacobian := match jacobian
        local
          // dummy map for strong component creation (no alias possible here)
          UnorderedMap<ComponentRef, SimVar> dummy_sim_map = UnorderedMap.new<SimVar>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, SimStrongComponent.Block> dummy_eqn_map = UnorderedMap.new<SimStrongComponent.Block>(ComponentRef.hash, ComponentRef.isEqual);
          SimStrongComponent.Block columnEqn;
          list<SimStrongComponent.Block> columnEqns = {};
          VarData varData;
          list<Pointer<Variable>> seed_lst, res_lst, tmp_lst;
          list<SimVar> seedVars, resVars, tmpVars;
          UnorderedMap<ComponentRef, SimVar> jac_map;
          SimJacobian jac;
          UnorderedMap<Identifier, Integer> sim_map;
          list<SimGenericCall> generic_loop_calls;
          UnorderedMap<ComponentRef, Integer> min_sub_map;
          UnorderedMap<ComponentRef, SimVar> min_sv_map;

        case BackendDAE.JACOBIAN(varData = varData as BVariable.VAR_DATA_JAC()) algorithm
          // temporarily save the generic call map from simcode to recover it afterwards
          // we use a local map to have seperated generic call lists for each jacobian
          sim_map := indices.generic_call_map;
          indices.generic_call_map := UnorderedMap.new<Integer>(Identifier.hash, Identifier.isEqual);
          for i in arrayLength(jacobian.comps):-1:1 loop
            (columnEqn, indices, _) := SimStrongComponent.Block.fromStrongComponent(jacobian.comps[i], indices, NBPartition.Kind.JAC, dummy_sim_map, dummy_eqn_map);
            columnEqns := columnEqn :: columnEqns;
          end for;

          // extract generic loop calls and put the old generic call map back
          generic_loop_calls := list(SimGenericCall.fromIdentifier(tpl) for tpl in UnorderedMap.toList(indices.generic_call_map));
          indices.generic_call_map := sim_map;

          if Flags.getConfigBool(Flags.SIM_CODE_SCALARIZE) then
            seed_lst := VariablePointers.toList(VariablePointers.scalarize(varData.seedVars));
            res_lst  := VariablePointers.toList(VariablePointers.scalarize(varData.resultVars));
            tmp_lst  := VariablePointers.toList(VariablePointers.scalarize(varData.tmpVars));
          else
            seed_lst := VariablePointers.toList(varData.seedVars);
            res_lst  := VariablePointers.toList(varData.resultVars);
            tmp_lst  := VariablePointers.toList(varData.tmpVars);
          end if;

          // column and seed var indices always start at 0
          seedVars := SimVar.createList(seed_lst, VarType.SIMULATION, NSimCode.EMPTY_SIM_CODE_INDICES());
          resVars  := SimVar.createList(res_lst,  VarType.SIMULATION, NSimCode.EMPTY_SIM_CODE_INDICES());
          tmpVars  := SimVar.createList(tmp_lst,  VarType.SIMULATION, NSimCode.EMPTY_SIM_CODE_INDICES());

          jac_map := UnorderedMap.new<SimVar>(ComponentRef.hash, ComponentRef.isEqual, listLength(seedVars) + listLength(resVars) + listLength(tmpVars));
          SimCodeUtil.addListSimCodeMap(seedVars, jac_map);
          SimCodeUtil.addListSimCodeMap(resVars, jac_map);
          SimCodeUtil.addListSimCodeMap(tmpVars, jac_map);

          // For per-element seed groups that start above index [1] (partial-slice
          // NLS iter vars), add a virtual SimVar keyed on the base cref (no
          // subscripts).  Templates look up $SEED.x when they see $SEED.x[$i1]
          // with an iterator subscript; the virtual SimVar's index encodes the
          // offset so (&seedVars[index])[$i1-1] reaches the correct element.
          //
          // Two-pass: first find the MINIMUM outer subscript per base-cref group
          // (the hash-ordered seedVars traversal does not guarantee ascending
          // module order), then create virtual SimVars using that minimum seed so
          // the base index is always non-negative.
          min_sub_map := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
          min_sv_map  := UnorderedMap.new<SimVar>(ComponentRef.hash, ComponentRef.isEqual);

          for sv in seedVars loop
            if ComponentRef.hasSubscripts(sv.name) then
              () := match ComponentRef.outermostIntegerSubscript(sv.name)
                local
                  ComponentRef base_cref;
                  Integer sub_val, cur_min;
                case sub_val guard sub_val > 1
                  algorithm
                    base_cref := ComponentRef.stripSubscriptsAll(sv.name);
                    if UnorderedMap.contains(base_cref, min_sub_map) then
                      cur_min := UnorderedMap.getSafe(base_cref, min_sub_map, sourceInfo());
                      if sub_val < cur_min then
                        UnorderedMap.add(base_cref, sub_val, min_sub_map);
                        UnorderedMap.add(base_cref, sv, min_sv_map);
                      end if;
                    else
                      UnorderedMap.add(base_cref, sub_val, min_sub_map);
                      UnorderedMap.add(base_cref, sv, min_sv_map);
                    end if;
                  then ();
                else ();
              end match;
            end if;
          end for;

          for tpl in UnorderedMap.toList(min_sv_map) loop
            () := match tpl
              local
                ComponentRef base_cref;
                SimVar min_sv, virtual_sv;
                Integer cur_min;
              case (base_cref, min_sv)
                algorithm
                  cur_min := UnorderedMap.getSafe(base_cref, min_sub_map, sourceInfo());
                  if not UnorderedMap.contains(base_cref, jac_map) then
                    virtual_sv := min_sv;
                    virtual_sv.name := base_cref;
                    virtual_sv.index := min_sv.index - crefFlatOffset(min_sv.name);
                    virtual_sv.arrayCref := NONE();
                    UnorderedMap.add(base_cref, virtual_sv, jac_map);
                  end if;
                then ();
            end match;
          end for;

          jac := SIM_JAC(
            name                = jacobian.name,
            jacobianIndex       = indices.jacobianIndex,
            partitionIndex      = 0,
            numberOfResultVars  = SimVars.numScalarElems(resVars),
            columnEqns          = columnEqns,
            constantEqns        = {},
            columnVars          = tmpVars,
            seedVars            = seedVars,
            sparsityMatrix      = Sparsity.create(jacobian.sparsity, SimVars.numScalarElems(resVars)),
            generic_loop_calls  = generic_loop_calls,
            jac_map             = SOME(jac_map),
            isAdjoint           = jacobian.isAdjoint,
            isBidirectional     = false,
            adjointJacobianIndex = -1,
            adjointMatrixName   = ""
          );

          indices.jacobianIndex := indices.jacobianIndex + 1;
          simJacobian := SOME(jac);
        then simJacobian;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end create;

    function createSimulationJacobian
      input list<Partition.Partition> partitions;
      output SimJacobian simJac;
      output SimJacobian simJacAdjoint;
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      list<BackendDAE> jacobians = {}, jacobiansAdjoint = {};
      BackendDAE simJacobian, simJacobianAdjoint;
      Option<SimJacobian> simJac_opt, simJacAdj_opt;
      Option<BackendDAE> jacobian, jacobianAdjoint;
    algorithm
      for partition in partitions loop
        // save jacobian if existent
        jacobian := Partition.Partition.getJacobian(partition);
        if isSome(jacobian) then
          jacobians := Util.getOption(jacobian) :: jacobians;
        end if;
        jacobianAdjoint := Partition.Partition.getJacobianAdjoint(partition);
        if isSome(jacobianAdjoint) then
          jacobiansAdjoint := Util.getOption(jacobianAdjoint) :: jacobiansAdjoint;
        end if;
      end for;

      // create empty jacobian as fallback
      // ToDo: handle simCodeIndices correctly here
      if listEmpty(jacobians) then
        (simJac, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
      else
        simJacobian := Jacobian.combine(jacobians, "A");
        (simJac_opt, simCodeIndices) := SimJacobian.create(simJacobian, simCodeIndices, simcode_map);
        if isSome(simJac_opt) then
          simJac := Util.getOption(simJac_opt);
        else
          (simJac, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
        end if;
      end if;

      // create empty adjoint jacobian as fallback
      if listEmpty(jacobiansAdjoint) then
        (simJacAdjoint, simCodeIndices) := SimJacobian.empty("ADJ", simCodeIndices);
      else
        simJacobianAdjoint := Jacobian.combine(jacobiansAdjoint, "ADJ");
        (simJacAdj_opt, simCodeIndices) := SimJacobian.create(simJacobianAdjoint, simCodeIndices, simcode_map);
        if isSome(simJacAdj_opt) then
          simJacAdjoint := Util.getOption(simJacAdj_opt);
        else
          (simJacAdjoint, simCodeIndices) := SimJacobian.empty("ADJ", simCodeIndices);
        end if;
      end if;

      // Link forward and adjoint for bidirectional mode
      if Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN) == "bidirectional" then
        simJac := match simJac
          case SIM_JAC() algorithm
            simJac.isBidirectional := true;
            simJac.adjointJacobianIndex := match simJacAdjoint case SIM_JAC() then simJacAdjoint.jacobianIndex; else -1; end match;
            simJac.adjointMatrixName   := match simJacAdjoint case SIM_JAC() then simJacAdjoint.name; else ""; end match;
          then simJac;
          else simJac;
        end match;
      end if;
    end createSimulationJacobian;

    function createOptimizationJacobian
      input list<Partition.Partition> partitions;
      output SimJacobian simJacLfg;
      output SimJacobian simJacMrf;
      output SimJacobian simJacR0;
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      list<BackendDAE> jacobiansLfg = {}, jacobiansMrf = {}, jacobiansR0 = {};
      BackendDAE simJacobianLfg, simJacobianMrf, simJacobianR0;
      Option<SimJacobian> simJacLfg_opt, simJacMrf_opt, simJacR0_opt;
      Option<BackendDAE> jacobianLfg, jacobianMrf, jacobianR0;
    algorithm
      for partition in partitions loop
        // collect
        jacobianLfg := Partition.Partition.getJacobianLfg(partition);
        if isSome(jacobianLfg) then
          jacobiansLfg := Util.getOption(jacobianLfg) :: jacobiansLfg;
        end if;
        jacobianMrf := Partition.Partition.getJacobianMrf(partition);
        if isSome(jacobianMrf) then
          jacobiansMrf := Util.getOption(jacobianMrf) :: jacobiansMrf;
        end if;
        jacobianR0 := Partition.Partition.getJacobianR0(partition);
        if isSome(jacobianR0) then
          jacobiansR0 := Util.getOption(jacobianR0) :: jacobiansR0;
        end if;
      end for;

      // create empty Lfg jacobian as fallback
      if listEmpty(jacobiansLfg) then
        (simJacLfg, simCodeIndices) := SimJacobian.empty("OPT_LFG", simCodeIndices);
      else
        simJacobianLfg := Jacobian.combine(jacobiansLfg, "OPT_LFG");
        (simJacLfg_opt, simCodeIndices) := SimJacobian.create(simJacobianLfg, simCodeIndices, simcode_map);
        if isSome(simJacLfg_opt) then
          simJacLfg := Util.getOption(simJacLfg_opt);
        else
          (simJacLfg, simCodeIndices) := SimJacobian.empty("OPT_LFG", simCodeIndices);
        end if;
      end if;

      // create empty Mrf jacobian as fallback
      if listEmpty(jacobiansMrf) then
        (simJacMrf, simCodeIndices) := SimJacobian.empty("OPT_MRF", simCodeIndices);
      else
        simJacobianMrf := Jacobian.combine(jacobiansMrf, "OPT_MRF");
        (simJacMrf_opt, simCodeIndices) := SimJacobian.create(simJacobianMrf, simCodeIndices, simcode_map);
        if isSome(simJacMrf_opt) then
          simJacMrf := Util.getOption(simJacMrf_opt);
        else
          (simJacMrf, simCodeIndices) := SimJacobian.empty("OPT_MRF", simCodeIndices);
        end if;
      end if;

      // create empty R0 jacobian as fallback
      if listEmpty(jacobiansR0) then
        (simJacR0, simCodeIndices) := SimJacobian.empty("OPT_R0", simCodeIndices);
      else
        simJacobianR0 := Jacobian.combine(jacobiansR0, "OPT_R0");
        (simJacR0_opt, simCodeIndices) := SimJacobian.create(simJacobianR0, simCodeIndices, simcode_map);
        if isSome(simJacR0_opt) then
          simJacR0 := Util.getOption(simJacR0_opt);
        else
          (simJacR0, simCodeIndices) := SimJacobian.empty("OPT_R0", simCodeIndices);
        end if;
      end if;
    end createOptimizationJacobian;

    function empty
      input String name = "";
      output SimJacobian emptyJac = EMPTY_SIM_JAC;
      input output SimCode.SimCodeIndices indices;
    algorithm
      emptyJac := match emptyJac
        case SIM_JAC() algorithm
          emptyJac.name := name;
          emptyJac.jacobianIndex := indices.jacobianIndex;
          indices.jacobianIndex := indices.jacobianIndex + 1;
        then emptyJac;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end empty;

    function getJacobianBlocks
      input SimJacobian jacobian;
      output list<SimStrongComponent.Block> blcks;
    algorithm
      blcks := match jacobian
        case SIM_JAC() then listAppend(jacobian.constantEqns, jacobian.columnEqns);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end getJacobianBlocks;

    function getJacobiansBlocks
      input list<SimJacobian> jacobians;
      output list<SimStrongComponent.Block> blcks = {};
    algorithm
      for jacobian in jacobians loop
        blcks := listAppend(getJacobianBlocks(jacobian), blcks);
      end for;
    end getJacobiansBlocks;

    function getJacobianHT
      input SimJacobian jacobian;
      output Option<UnorderedMap<ComponentRef, SimVar>> jac_map;
    algorithm
      jac_map := match jacobian
        case SIM_JAC() then jacobian.jac_map;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end getJacobianHT;

    function convert
      input SimJacobian simJac;
      output OldSimCode.JacobianMatrix oldJac;
    protected
      OldSimCode.JacobianColumn oldJacCol;
    algorithm
      oldJac := match simJac
        local
          ConvertMemo memo;
        case SIM_JAC() algorithm
          memo := SimVar.newConvertMemo(listLength(simJac.seedVars) + listLength(simJac.columnVars));
          oldJacCol := OldSimCode.JAC_COLUMN(
            columnEqns          = list(SimStrongComponent.Block.convert(blck) for blck in simJac.columnEqns),
            columnVars          = SimVar.convertListMemo(simJac.columnVars, memo),
            numberOfResultVars  = simJac.numberOfResultVars,
            constantEqns        = list(SimStrongComponent.Block.convert(blck) for blck in simJac.constantEqns)
          );

          oldJac := OldSimCode.JAC_MATRIX(
            columns             = {oldJacCol},
            seedVars            = SimVar.convertListMemo(simJac.seedVars, memo),
            matrixName          = simJac.name,
            sparsityMatrix      = Sparsity.convert(simJac.sparsityMatrix),
            sparsity            = {},
            sparsityT           = {},
            nonlinear           = {},
            nonlinearT          = {},
            coloredCols         = {},
            coloredRows         = {},
            maxColorCols        = 0,
            jacobianIndex       = simJac.jacobianIndex,
            partitionIndex      = simJac.partitionIndex,
            generic_loop_calls  = list(SimGenericCall.convert(gc) for gc in simJac.generic_loop_calls),
            crefsHT             = Util.applyOption(simJac.jac_map, function SimCodeUtil.convertSimCodeMap(memo = memo)),
            isAdjoint           = simJac.isAdjoint,
            isBidirectional     = simJac.isBidirectional,
            adjointJacobianIndex = simJac.adjointJacobianIndex,
            adjointMatrixName   = simJac.adjointMatrixName
          );
        then oldJac;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end convert;
  end SimJacobian;

  constant SimJacobian EMPTY_SIM_JAC = SIM_JAC("", 0, 0, 0, {}, {}, {}, {},
    Sparsity.EMPTY(), {}, NONE(), false, false, -1, "");

  protected function collectNodeSubDimPairsOuterFirst
    "Collect (sub_val, dim_size) pairs for a single CREF node's subscripts and
     dimension list, in outer→inner (natural subscript) order. Only INTEGER
     subscripts are included; non-integer subscripts consume their dimension slot
     without emitting a pair. Always has an else case."
    input list<Subscript> subs;
    input list<Dimension> dims;
    output list<tuple<Integer, Integer>> pairs;
  algorithm
    pairs := match (subs, dims)
      local
        Subscript s;
        list<Subscript> rest_subs;
        Dimension d;
        list<Dimension> rest_dims;
        Integer v, v3;
        list<tuple<Integer, Integer>> rest_pairs;
      case ({}, _) then {};
      case ({Subscript.INDEX(index = Expression.INTEGER(v3))}, {}) then {(v3, 1)};
        // InstNode.getType(node) can come back without array dims for a seed's own
        // node (e.g. an INIT-partition per-element seed cref, whose leaf node's
        // declared type resolves to a bare scalar even though it indexes an array
        // -- see the ODE partition's equivalent cref, whose node keeps its proper
        // Real[n] type, for the same conceptual variable). When this is the node's
        // ONLY subscript, falling all the way through to `{}` (as the general
        // multi-subscript case below still does) would silently drop this
        // dimension's contribution to the flat offset entirely -- exactly the
        // "sizeCols/size mismatch" class of bug this whole file exists to avoid.
        // A dim_size of 1 is always safe here: this pair is the innermost/only
        // one from this node, so nothing multiplies by it going outward, and
        // (v3-1)*1 is exactly the correct offset contribution.
      case (_, {}) then {};
      case (s :: rest_subs, d :: rest_dims)
        algorithm
          rest_pairs := collectNodeSubDimPairsOuterFirst(rest_subs, rest_dims);
        then
          match s
            local Integer v2;
            case Subscript.INDEX(index = Expression.INTEGER(v2)) then (v2, Dimension.size(d)) :: rest_pairs;
            else rest_pairs;
          end match;
      else {};
    end match;
  end collectNodeSubDimPairsOuterFirst;

  protected function crefSubDimPairsLeafToRoot
    "Collect (integer_subscript_value, dimension_size) pairs from the innermost
     (leaf) CREF node to the outermost (root), in inner-first order globally.
     Within each node, multiple subscripts are handled in inner→outer order
     (reversed from the outer→inner subscript list so the accumulation works).
     Uses InstNode.getType(node) (the pre-subscript type) rather than cref.ty
     (the post-subscript element type) so that record-field subscripts like
     module[2] (where cref.ty = Module, not Module[10]) recover the full array
     dimension needed to compute correct flat offsets."
    input ComponentRef cref;
    output list<tuple<Integer, Integer>> pairs;
  algorithm
    pairs := match cref
      local
        list<Subscript> subs;
        Type node_ty;
        ComponentRef rest;
        list<tuple<Integer, Integer>> rest_pairs, node_pairs;
      case ComponentRef.CREF(node = _, subscripts = subs, restCref = rest)
        algorithm
          rest_pairs := crefSubDimPairsLeafToRoot(rest);
          // Use the node's own declared type (before applying these subscripts)
          // so record-valued fields also expose their array dimensions.
          node_ty := InstNode.getType(cref.node);
          // Collect this node's pairs outer-first, then reverse to get inner-first.
          // Append rest_pairs (which are from the outer/restCref direction) after.
          node_pairs := listReverse(collectNodeSubDimPairsOuterFirst(subs, Type.arrayDims(node_ty)));
        then
          listAppend(node_pairs, rest_pairs);
      else {};
    end match;
  end crefSubDimPairsLeafToRoot;

  protected function crefFlatOffset
    "Compute the 0-based flat array index encoded by all integer subscripts in
     the cref chain, using row-major (C-style) layout. For example, x[2][1] in
     a 10×10 array returns (2-1)*10 + (1-1) = 10. Used to compute the virtual
     SimVar index so that (&seedVars[virtual.idx])[(i1-1)*d2+...+(iN-1)] maps
     correctly to the actual seed index for every valid subscript combination."
    input ComponentRef cref;
    output Integer offset = 0;
  protected
    list<tuple<Integer, Integer>> pairs;
    Integer inner_prod = 1, sub_val, dim_sz;
  algorithm
    // pairs is in inner-first order: process each pair with accumulated inner_prod.
    // flat = sum_i (sub[i]-1) * product_of_dims_more_inner_than_i
    pairs := crefSubDimPairsLeafToRoot(cref);
    for pair in pairs loop
      (sub_val, dim_sz) := pair;
      offset := offset + (sub_val - 1) * inner_prod;
      inner_prod := inner_prod * dim_sz;
    end for;
  end crefFlatOffset;

  annotation(__OpenModelica_Interface="nbackend");
end NSimJacobian;
