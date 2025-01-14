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
encapsulated package NSimStrongComponent
"file:        NSimStrongComponent.mo
 package:     NSimStrongComponent
 description: This file contains the data types and functions for strong
              components in simulation code phase.
"

protected
  // OF imports
  import DAE;

  // NF imports
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import Expression = NFExpression;
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import InstNode = NFInstNode.InstNode;
  import Operator = NFOperator;
  import Scalarize = NFScalarize;
  import Statement = NFStatement;
  import Type = NFType;
  import Variable = NFVariable;

  // old backend imports
  import OldBackendDAE = BackendDAE;

  // Backend imports
  import AliasInfo = NBStrongComponent.AliasInfo;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationAttributes, EquationKind, EquationPointer, EquationPointers, WhenEquationBody, WhenStatement, IfEquationBody, Iterator, SlicingStatus};
  import Solve = NBSolve;
  import StrongComponent = NBStrongComponent;
  import Partition = NBPartition;
  import NBPartitioning.{BClock, ClockedInfo};
  import Tearing = NBTearing;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Old SimCode imports
  import OldSimCode = SimCode;

  // SimCode imports
  import SimCode = NSimCode;
  import NSimCode.SimCodeIndices;
  import NSimJacobian.SimJacobian;
  import NSimCode.Identifier;
  import SimPartition = NSimPartition;
  import NSimPartition.SimPartitions;
  import NSimVar.{SimVar, SimVars, VarType};

  // Util imports
  import Error;
  import Slice = NBSlice;
  import StringUtil;

public
  uniontype Block
    "A single blck from BLT transformation."

    record RESIDUAL
      "Single residual equation of the form
      0 = exp"
      Integer index;
      Integer res_index;
      Expression exp;
      DAE.ElementSource source;
      EquationAttributes attr;
    end RESIDUAL;

    record ARRAY_RESIDUAL
      "Single residual array equation of the form
      0 = exp. Structurally equal to RESIDUAL, but the destinction is important
      for code generation."
      Integer index;
      Integer res_index;
      Expression exp;
      DAE.ElementSource source;
      EquationAttributes attr;
    end ARRAY_RESIDUAL;

    record FOR_RESIDUAL
      "for-loop residual equation of the form
      for {i in 1:n, j in 1:m, ...} loop
        0 = exp;
      end for;"
      Integer index;
      Integer res_index;
      list<tuple<ComponentRef, Expression>> iterators;
      Expression exp;
      DAE.ElementSource source;
      EquationAttributes attr;
    end FOR_RESIDUAL;

    record GENERIC_RESIDUAL
      "a generic residual calling a for loop body function with an index list."
      Integer index;
      Integer res_index;
      list<Integer> scal_indices;
      list<tuple<ComponentRef, Expression>> iterators;
      Expression exp;
      DAE.ElementSource source;
      EquationAttributes attr;
    end GENERIC_RESIDUAL;

    record SIMPLE_ASSIGN
      "Simple assignment or solved inner equation of (casual) tearing set
      (Dynamic Tearing) with constraints on the solvability
      lhs := rhs"
      Integer index;
      ComponentRef lhs "left hand side of equation";
      Expression rhs;
      DAE.ElementSource source;
      // ToDo: this needs to be added for tearing later on
      //Option<BackendDAE.Constraints> constraints;
      EquationAttributes attr;
    end SIMPLE_ASSIGN;

    record ARRAY_ASSIGN
      "Array assignment where the left hand side can be an array constructor.
      {a, b, ...} := rhs"
      Integer index;
      Expression lhs;
      Expression rhs;
      DAE.ElementSource source;
      EquationAttributes attr;
    end ARRAY_ASSIGN;

    record GENERIC_ASSIGN
      "a generic assignment calling a for loop body function with an index list."
      Integer index;
      Integer call_index;
      list<Integer> scal_indices;
      DAE.ElementSource source;
      EquationAttributes attr;
    end GENERIC_ASSIGN;

    record ENTWINED_ASSIGN
      "entwined generic assignments calling for loop body functions with an index list and a call order."
      Integer index;
      list<Integer> call_order;
      list<Block> single_calls;
      DAE.ElementSource source;
      EquationAttributes attr;
    end ENTWINED_ASSIGN;

    record ALIAS
      "Simple alias assignment pointing to the alias equation.
      - alias of will be -1 at the point of creation and computed afterwards"
      Integer index;
      AliasInfo aliasInfo     "backend alias info";
      Integer aliasOf         "final alias index";
    end ALIAS;

    record ALGORITHM
      "An algorithm section."
      // ToDo: do we need to keep inputs/outputs here?
      Integer index;
      list<Statement> stmts;
      EquationAttributes attr;
    end ALGORITHM;

    record INVERSE_ALGORITHM
      "An algorithm section that had to be inverted."
      Integer index;
      list<Statement> stmts;
      list<ComponentRef> knownOutputs "this is a subset of output crefs of the original algorithm, which are already known";
      Boolean insideNonLinearSystem;
      EquationAttributes attr;
    end INVERSE_ALGORITHM;

    record IF
      "An if section."
      Integer index;
      list<tuple<Expression, list<Block>>> branches;
      DAE.ElementSource source;
      EquationAttributes attr;
    end IF;

    record WHEN
      "A when section."
      Integer index;
      Boolean initialCall "true, if top-level branch with initial()";
      list<ComponentRef> conditions;
      list<WhenStatement> when_stmts;
      Option<Block> else_when;
      DAE.ElementSource source;
      EquationAttributes attr;
    end WHEN;

    record LINEAR
      "Linear algebraic loop."
      LinearSystem system;
      Option<LinearSystem> alternativeTearing;
    end LINEAR;

    record NONLINEAR
      "Nonlinear algebraic loop."
      NonlinearSystem system;
      Option<NonlinearSystem> alternativeTearing;
    end NONLINEAR;

    record HYBRID
      "Hyprid system containing both continuous and discrete equations."
      Integer index;
      Block continuous;
      list<SimVar> discreteVars;
      list<Block> discreteEqs;
      Integer indexHybridSystem;
    end HYBRID;

    function toString
      // ToDo: Update alias string to print actual name. Update structure?
      input Block blck;
      input output String str = "";
    algorithm
      str := match blck
        case RESIDUAL()           then str + "(" + intString(blck.index) + ") 0 = " + Expression.toString(blck.exp) + "\n";
        case ARRAY_RESIDUAL()     then str + "(" + intString(blck.index) + ") 0 = " + Expression.toString(blck.exp) + "\n";
        case FOR_RESIDUAL()       then str + "(" + intString(blck.index) + ") For-Loop-Residual:\n" + str + "for " + List.toString(blck.iterators, forTplStr) + " loop\n" + str + "  0 = " + Expression.toString(blck.exp) + ";\n" + str + "end for;\n";
        case GENERIC_RESIDUAL()   then str + "(" + intString(blck.index) + ") Generic For-Loop-Residual:\n" + str + List.toString(blck.scal_indices, intString, "slice", "{", ", ", "}", true, 10) + "\n" + str + "for " + List.toString(blck.iterators, forTplStr) + " loop\n" + str + "  0 = " + Expression.toString(blck.exp) + ";\n" + str + "end for;\n";
        case SIMPLE_ASSIGN()      then str + "(" + intString(blck.index) + ") " + ComponentRef.toString(blck.lhs) + " := " + Expression.toString(blck.rhs) + "\n";
        case ARRAY_ASSIGN()       then str + "(" + intString(blck.index) + ") " + Expression.toString(blck.lhs) + " := " + Expression.toString(blck.rhs) + "\n";
        case GENERIC_ASSIGN()     then str + "(" + intString(blck.index) + ") " + "single generic call [index  " + intString(blck.call_index) + "] " + List.toString(inList = blck.scal_indices, inPrintFunc = intString, maxLength = 10) + "\n";
        case ENTWINED_ASSIGN()    then str + List.toString(blck.single_calls, function toString(str=""), "### entwined call (" + intString(blck.index) + ") ###", "\n    ", "    ", "");
        case ALIAS()              then str + "(" + intString(blck.index) + ") Alias of " + intString(blck.aliasOf) + "\n";
        case ALGORITHM()          then str + "(" + intString(blck.index) + ") Algorithm\n" + Statement.toStringList(blck.stmts, str);
        case INVERSE_ALGORITHM()  then str + "(" + intString(blck.index) + ") Inverse Algorithm\n" + Statement.toStringList(blck.stmts, str) + "\n";
        case IF()                 then str + "(" + intString(blck.index) + ") " + List.toString(blck.branches, function ifTplStr(str = str), "", str, str + "else ", str + "end if;\n");
        case WHEN()               then str + "(" + intString(blck.index) + ") " + whenString(blck.conditions, blck.when_stmts, blck.else_when, str);
        case LINEAR()             then str + "(" + intString(blck.system.index) + ") " + LinearSystem.toString(blck.system, str);
        case NONLINEAR()          then str + "(" + intString(blck.system.index) + ") " + NonlinearSystem.toString(blck.system, str);
        case HYBRID()             then str + "(" + intString(blck.index) + ") Hybrid\n"; // ToDo!
                                  else getInstanceName() + " failed.\n";
      end match;
    end toString;

    function forTplStr
      input tuple<ComponentRef, Expression> tpl;
      output String str;
    protected
      ComponentRef name;
      Expression range;
    algorithm
      (name, range) := tpl;
      str := ComponentRef.toString(name) + " in " + Expression.toString(range);
    end forTplStr;

    function ifTplStr
      input tuple<Expression, list<Block>> tpl;
      input output String str;
    protected
      Expression condition;
      list<Block> blcks;
    algorithm
      (condition, blcks) := tpl;
      str := "if " + Expression.toString(condition) + " then\n  "
         + List.toString(blcks, function toString(str = str + "  "), "", "", "\n", "");
    end ifTplStr;

    function getIndex
      input Block blck;
      output Integer index;
    algorithm
      index := match blck
        case RESIDUAL()           then blck.index;
        case ARRAY_RESIDUAL()     then blck.index;
        case FOR_RESIDUAL()       then blck.index;
        case SIMPLE_ASSIGN()      then blck.index;
        case ARRAY_ASSIGN()       then blck.index;
        case GENERIC_ASSIGN()     then blck.index;
        case ENTWINED_ASSIGN()    then blck.index;
        case ALIAS()              then blck.index;
        case ALGORITHM()          then blck.index;
        case INVERSE_ALGORITHM()  then blck.index;
        case IF()                 then blck.index;
        case WHEN()               then blck.index;
        case LINEAR()             then blck.system.index;
        case NONLINEAR()          then blck.system.index;
        case HYBRID()             then blck.index;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(blck)});
        then fail();
      end match;
    end getIndex;

    function isDiscrete
      input Block blck;
      output Boolean b;
    algorithm
      b := match blck
        local
          EquationAttributes attr;
        case RESIDUAL(attr = attr)          then attr.kind == EquationKind.DISCRETE;
        case ARRAY_RESIDUAL(attr = attr)    then attr.kind == EquationKind.DISCRETE;
        case FOR_RESIDUAL(attr = attr)      then attr.kind == EquationKind.DISCRETE;
        case SIMPLE_ASSIGN(attr = attr)     then attr.kind == EquationKind.DISCRETE;
        case ARRAY_ASSIGN(attr = attr)      then attr.kind == EquationKind.DISCRETE;
        case GENERIC_ASSIGN(attr = attr)    then attr.kind == EquationKind.DISCRETE;
        case ENTWINED_ASSIGN(attr = attr)   then attr.kind == EquationKind.DISCRETE;
        case ALIAS()                        then false; // todo: once this is implemented check in the HT for alias eq discrete
        case ALGORITHM(attr = attr)         then attr.kind == EquationKind.DISCRETE;
        case INVERSE_ALGORITHM(attr = attr) then attr.kind == EquationKind.DISCRETE;
        case IF(attr = attr)                then attr.kind == EquationKind.DISCRETE;
        case WHEN(attr = attr)              then attr.kind == EquationKind.DISCRETE; // should hopefully always be true
        else false;
      end match;
    end isDiscrete;

    function isWhen
      input Block blck;
      output Boolean b;
    algorithm
      b := match blck
        case WHEN() then true;
        else false;
      end match;
    end isWhen;

    function map
      "ToDo: other blocks and cref func"
      input output Block blck;
      input expFunc func;
      partial function expFunc
        input output Expression exp;
      end expFunc;
    algorithm
      blck := match blck
        case RESIDUAL() algorithm
          blck.exp := Expression.map(blck.exp, func);
        then blck;

        case SIMPLE_ASSIGN() algorithm
          blck.rhs := Expression.map(blck.rhs, func);
        then blck;

        else blck;
      end match;
    end map;

    function listToString
      input list<Block> blcks;
      input output String str = "";
      input String header = "";
    protected
      String indent = str;
    algorithm
      str := if header <> "" then StringUtil.headline_3(header) else "";
      for blck in blcks loop
        str := str + Block.toString(blck, indent);
      end for;
    end listToString;

    function createBlocks
      input list<Partition.Partition> partitions;
      output list<list<Block>> blcks = {};
      input output list<Block> all_blcks;
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      list<Block> tmp;
    algorithm
      for partition in partitions loop
        (tmp, simCodeIndices) := fromPartition(partition, simCodeIndices, simcode_map, equation_map);
        blcks := tmp :: blcks;
        all_blcks := listAppend(tmp, all_blcks);
      end for;
      blcks := listReverse(blcks);
    end createBlocks;

    function createDiscreteBlocks
      input list<Partition.Partition> partitions;
      input output list<list<Block>> blcks;
      input output list<Block> all_blcks;
      input output list<Block> event_dependencies;
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      list<Block> tmp;
    algorithm
      for partition in partitions loop
        (tmp, simCodeIndices) := fromPartition(partition, simCodeIndices, simcode_map, equation_map);
        // add all
        all_blcks := listAppend(tmp, all_blcks);
        // filter all when equations and add to blcks (ode or algebraic)
        tmp := list(blck for blck guard(not isWhen(blck)) in tmp);
        blcks := tmp :: blcks;
        // filter all other discrete equations and add to event_dependencies
        tmp := list(blck for blck guard(not isDiscrete(blck)) in tmp);
        event_dependencies := listAppend(tmp, event_dependencies);
      end for;
      blcks := listReverse(blcks);
    end createDiscreteBlocks;

    function createInitialBlocks
      input list<Partition.Partition> partitions;
      output list<Block> blcks;
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      list<Block> tmp;
      list<list<Block>> tmp_lst = {};
    algorithm
      for partition in partitions loop
        (tmp, simCodeIndices) := fromPartition(partition, simCodeIndices, simcode_map, equation_map);
        tmp_lst := tmp :: tmp_lst;
      end for;
      blcks := List.flatten(tmp_lst);
    end createInitialBlocks;

    function createDAEModeBlocks
      input list<Partition.Partition> partitions;
      output list<list<Block>> blcks = {};
      output list<SimVar> vars = {};
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      Pointer<SimCodeIndices> indices_ptr;
      Pointer<list<SimVar>> vars_ptr = Pointer.create({});
      list<Block> tmp;
    algorithm
      for partition in listReverse(partitions) loop
        indices_ptr := Pointer.create(simCodeIndices);
        VariablePointers.map(partition.unknowns, function SimVar.traverseCreate(acc = vars_ptr, indices_ptr = indices_ptr, varType = VarType.RESIDUAL));
        (tmp, simCodeIndices) := fromPartition(partition, Pointer.access(indices_ptr), simcode_map, equation_map);
        blcks := tmp :: blcks;
      end for;
      vars := listReverse(Pointer.access(vars_ptr));
    end createDAEModeBlocks;

    function createClockedBlocks
      input list<Partition.Partition> partitions;
      output SimPartitions baseParts;
      output list<Block> eventClocks;
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
      input ClockedInfo info;
    protected
      UnorderedMap<BClock, SimPartitions> clock_collector = UnorderedMap.new<SimPartitions>(BClock.hash, BClock.isEqual);
      list<Block> blcks;
      list<SimVar> vars;
      BClock clock, subClock, baseClock;
      Boolean holdEvents;
      Option<BClock> baseClock_opt;
      SimPartition basePart, subPart;
    algorithm
      // collect all base clocks
      for c in UnorderedMap.valueList(info.baseClocks) loop
        UnorderedMap.add(c, {}, clock_collector);
      end for;

      // create all sub partition blocks and find the base partitions
      for partition in listReverse(partitions) loop
        (blcks, simCodeIndices)             := fromPartition(partition, simCodeIndices, simcode_map, equation_map);
        vars                                := SimVars.getPartitionVars(partition, simcode_map);
        (clock, baseClock_opt, holdEvents)  := Partition.Partition.getClocks(partition);
        if Util.isSome(baseClock_opt) then
          // it is a sub clock
          SOME(baseClock) := baseClock_opt;
          subClock        := clock;
        else
          // it is a base clock, use the default sub clock
          baseClock       := clock;
          subClock        := NBPartitioning.DEFAULT_SUB_CLOCK;
        end if;
        subPart := SimPartition.createSubPartition(subClock, blcks, vars, holdEvents);
        UnorderedMap.add(baseClock, subPart :: UnorderedMap.getSafe(baseClock, clock_collector, sourceInfo()), clock_collector);
      end for;

      // create base partitions
      (baseParts, eventClocks, simCodeIndices) := SimPartition.createBasePartitions(clock_collector, simCodeIndices);
    end createClockedBlocks;

    function createNoReturnBlocks
      input EquationPointers equations;
      output list<Block> blcks = {};
      input output SimCodeIndices simCodeIndices;
      input Partition.Kind kind;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      Equation eqn;
      Block tmp;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eqn := Pointer.access(ExpandableArray.get(i, equations.eqArr));
          (tmp, simCodeIndices) := match eqn
            local
              ComponentRef cref;

            case Equation.SCALAR_EQUATION(lhs = Expression.CREF(cref = cref))
            then createEquation(NBVariable.getVar(cref), eqn, NBSolve.Status.EXPLICIT, simCodeIndices, kind, simcode_map, equation_map);

            case Equation.WHEN_EQUATION()
            then createEquation(NBVariable.DUMMY_VARIABLE, eqn, NBSolve.Status.EXPLICIT, simCodeIndices, kind, simcode_map, equation_map);

            case Equation.ALGORITHM()
            then createAlgorithm(eqn, simCodeIndices, equation_map);

            case Equation.FOR_EQUATION()
            then createAlgorithm(eqn, simCodeIndices, equation_map);

            /* ToDo: ARRAY_EQUATION ... */

            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + Equation.toString(eqn)});
            then fail();
          end match;

          blcks := tmp :: blcks;
          // list reverse necessary? they are unordered anyway
        end if;
      end for;
    end createNoReturnBlocks;

    function fromPartition
      input Partition.Partition partition;
      output list<Block> blcks;
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    algorithm
      blcks := match partition.strongComponents
        local
          array<StrongComponent> comps;
          Partition.Kind kind;
          Block tmp;
          list<Block> result = {};
          Integer index;

        case SOME(comps) algorithm
          kind := Partition.Partition.getKind(partition);
          for i in arrayLength(comps):-1:1 loop
            (tmp, simCodeIndices, index) := fromStrongComponent(comps[i], simCodeIndices, kind, simcode_map, equation_map);
            // add it to the alias map
            if not StrongComponent.isAlias(comps[i]) then
              UnorderedMap.add(AliasInfo.ALIAS_INFO(kind, partition.index, i), index, simCodeIndices.alias_map);
            end if;
            result := tmp :: result;
          end for;
        then result;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + Partition.Partition.toString(partition)});
        then fail();
      end match;
    end fromPartition;

    function fromStrongComponent
      input StrongComponent comp;
      output Block blck;
      input output SimCodeIndices simCodeIndices;
      output Integer index;
      input Partition.Kind kind;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    algorithm
      (blck, index) := match comp
        local
          Tearing strict;
          NonlinearSystem system;
          list<Block> result = {}, eqns = {};
          list<ComponentRef> crefs = {};
          Block tmp;
          Pointer<Variable> varPtr;
          Variable var;
          SimJacobian tmpJac;
          Option<SimJacobian> jacobian;
          EquationPointer eqn_ptr;
          Equation eqn;
          SlicingStatus status;
          ComponentRef var_cref;
          Integer aliasOf, generic_call_index, residual_index = 0;
          list<Integer> eqn_indices, sizes;
          list<Equation> entwined_eqns = {};
          UnorderedMap<ComponentRef, Expression> replacements;
          Block single_call;
          list<Block> single_calls = {};
          UnorderedMap<ComponentRef, Integer> entwined_index_map;
          list<Integer> call_order = {};
          Identifier ident;

        case StrongComponent.SINGLE_COMPONENT() algorithm
          (tmp, simCodeIndices) := createEquation(Pointer.access(comp.var), Pointer.access(comp.eqn), comp.status, simCodeIndices, kind, simcode_map, equation_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.MULTI_COMPONENT() algorithm
          (tmp, simCodeIndices) := createEquation(NBVariable.DUMMY_VARIABLE, Pointer.access(Slice.getT(comp.eqn)), comp.status, simCodeIndices, kind, simcode_map, equation_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.SLICED_COMPONENT() guard(Equation.isForEquation(Slice.getT(comp.eqn))) algorithm
          (tmp, simCodeIndices) := createAlgorithm(Pointer.access(Slice.getT(comp.eqn)), simCodeIndices, equation_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.SLICED_COMPONENT() algorithm
          // just a regular equation solved for a sliced variable
          // use cref instead of var because it has subscripts!
          eqn := Pointer.access(Slice.getT(comp.eqn));
          (tmp, simCodeIndices) := createEquation(Variable.fromCref(comp.var_cref), eqn, comp.status, simCodeIndices, kind, simcode_map, equation_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.RESIZABLE_COMPONENT() guard(Equation.isForEquation(Slice.getT(comp.eqn))) algorithm
          // for now create algorithms
          // ToDo: actually create resizable code
          (tmp, simCodeIndices) := createAlgorithm(Pointer.access(Slice.getT(comp.eqn)), simCodeIndices, equation_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.GENERIC_COMPONENT() algorithm
          // create a generic index list call of a for-loop equation
          eqn_ptr := Slice.getT(comp.eqn);
          eqn     := Pointer.access(eqn_ptr);
          ident   := Identifier.IDENTIFIER(eqn_ptr, comp.var_cref);
          generic_call_index := UnorderedMap.tryAdd(ident, UnorderedMap.size(simCodeIndices.generic_call_map), simCodeIndices.generic_call_map);
          tmp     := GENERIC_ASSIGN(simCodeIndices.equationIndex, generic_call_index, comp.eqn.indices, Equation.getSource(eqn), Equation.getAttributes(eqn));
          UnorderedMap.add(Equation.getEqnName(eqn_ptr), tmp, equation_map);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then (tmp, getIndex(tmp));

        case StrongComponent.ENTWINED_COMPONENT() algorithm
          // create generic index list calls for entwined for-loop equations
          entwined_index_map := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
          for slice in comp.entwined_slices loop
            (single_call, simCodeIndices, _) := fromStrongComponent(slice, simCodeIndices, kind, simcode_map, equation_map);
            UnorderedMap.add(getGenericEquationName(slice), getGenericAssignIndex(single_call), entwined_index_map);
            single_calls := single_call :: single_calls;
          end for;
          for tpl in listReverse(comp.entwined_tpl_lst) loop
            (eqn_ptr, _) := tpl;
            call_order := UnorderedMap.getSafe(Equation.getEqnName(eqn_ptr), entwined_index_map, sourceInfo()) :: call_order;
          end for;
          // todo: eq attributes and source
          tmp := ENTWINED_ASSIGN(simCodeIndices.equationIndex, call_order, single_calls, DAE.emptyElementSource, EquationAttributes.default(EquationKind.CONTINUOUS, false));
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then (tmp, getIndex(tmp));

        case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
          for i in 1:arrayLength(strict.innerEquations) loop
            (tmp, simCodeIndices, _) := fromStrongComponent(strict.innerEquations[i], simCodeIndices, kind, simcode_map, equation_map);
            eqns := tmp :: eqns;
          end for;
          for slice in strict.residual_eqns loop
            // kabdelhak: we need to actually slice here -> generic slices are needed for residuals
            (tmp, simCodeIndices, residual_index) := createResidual(slice, simCodeIndices, residual_index, equation_map);
            eqns := tmp :: eqns;
          end for;
          for slice in strict.iteration_vars loop
            var := Pointer.access(Slice.getT(slice));
            if Variable.size(var) > 1 then
              for scal_var in Scalarize.scalarizeBackendVariable(var, slice.indices) loop
                crefs := scal_var.name :: crefs;
              end for;
            else
              crefs := var.name :: crefs;
            end if;
          end for;

          // reactivate this once nonlinear loops actually work
          if false and Util.isSome(strict.jac) then
            (jacobian, simCodeIndices) := SimJacobian.create(Util.getOption(strict.jac), simCodeIndices, simcode_map);
          else
            jacobian := NONE();
          end if;
          system := NONLINEAR_SYSTEM(
            index         = simCodeIndices.equationIndex,
            blcks         = listReverse(eqns),
            crefs         = listReverse(crefs),
            indexSystem   = simCodeIndices.nonlinearSystemIndex,
            size          = listLength(crefs),
            jacobian      = Pointer.create(jacobian),
            homotopy      = false,
            mixed         = comp.mixed,
            torn          = true
          );
          simCodeIndices.nonlinearSystemIndex := simCodeIndices.nonlinearSystemIndex + 1;
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then (NONLINEAR(system, NONE()), system.index);

        case StrongComponent.ALIAS() algorithm
          aliasOf := UnorderedMap.getOrDefault(comp.aliasInfo, simCodeIndices.alias_map, -1);
          tmp := ALIAS(simCodeIndices.equationIndex, comp.aliasInfo, aliasOf);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then (tmp, getIndex(tmp));

        case StrongComponent.ENTWINED_COMPONENT() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because entwined equations have to be resolved beforehand in Solve.solve(). Failed for:\n"
            + StrongComponent.toString(comp)});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with unknown reason for \n" + StrongComponent.toString(comp)});
        then fail();
      end match;
    end fromStrongComponent;

    function createResidual
      input Slice<EquationPointer> slice;
      output Block blck;
      input output SimCodeIndices simCodeIndices;
      input output Integer res_idx;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      Equation eqn = Pointer.access(Slice.getT(slice));
    algorithm
      blck := match (eqn, slice.indices)
        local
          Block tmp;
          list<ComponentRef> names;
          list<Expression> ranges;

        case (BEquation.SCALAR_EQUATION(), {}) algorithm
          tmp := RESIDUAL(simCodeIndices.equationIndex, res_idx, eqn.rhs, eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
          res_idx := res_idx + 1;
        then tmp;

        case (BEquation.ARRAY_EQUATION(), {}) algorithm
          tmp := ARRAY_RESIDUAL(simCodeIndices.equationIndex, res_idx, eqn.rhs, eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
          res_idx := res_idx + Equation.size(Slice.getT(slice));
        then tmp;

        case (BEquation.IF_EQUATION(), _) algorithm
          (tmp, simCodeIndices, res_idx) := createResidual(Slice.SLICE(Pointer.create(IfEquationBody.inline(eqn.body, eqn)), slice.indices), simCodeIndices, res_idx, equation_map);
        then tmp;

        // for equations have to be split up before. Since they are not causalized
        // they can be executed in any order
        case (BEquation.FOR_EQUATION(body = {_}), {}) algorithm
          (names, ranges) := Iterator.getFrames(eqn.iter);
          tmp := FOR_RESIDUAL(simCodeIndices.equationIndex, res_idx, List.zip(names, ranges), Equation.getRHS(eqn), eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
          res_idx := res_idx + Equation.size(Slice.getT(slice));
        then tmp;

        // generic residual, for loop could not be fully recovered
        case (BEquation.FOR_EQUATION(body = {_}), _) algorithm
          (names, ranges) := Iterator.getFrames(eqn.iter);
          tmp := GENERIC_RESIDUAL(simCodeIndices.equationIndex, res_idx, slice.indices, List.zip(names, ranges), Equation.getRHS(eqn), eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
          res_idx := res_idx + listLength(slice.indices);
        then tmp;

        // ToDo: add all other cases!

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + Equation.toString(eqn)});
        then fail();

      end match;
      UnorderedMap.add(Equation.getEqnName(Pointer.create(eqn)), blck, equation_map);
    end createResidual;

    function createEquation
      "Creates a single equation"
      input Variable var;
      input Equation eqn;
      input Solve.Status status;
      output Block blck;
      input output SimCodeIndices simCodeIndices;
      input Partition.Kind kind;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    algorithm
      blck := match (eqn, status)
        local
          Type ty;
          Operator operator;
          Expression lhs, rhs;
          Block tmp;
          list<tuple<Expression, list<Block>>> branches;

        case (BEquation.SCALAR_EQUATION(), NBSolve.Status.EXPLICIT) algorithm
          tmp := SIMPLE_ASSIGN(simCodeIndices.equationIndex, var.name, eqn.rhs, eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case (BEquation.ARRAY_EQUATION(), NBSolve.Status.EXPLICIT) algorithm
          tmp := ARRAY_ASSIGN(simCodeIndices.equationIndex, eqn.lhs, eqn.rhs, eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case (BEquation.RECORD_EQUATION(), NBSolve.Status.EXPLICIT) algorithm
          (tmp, simCodeIndices) := createAlgorithm(eqn, simCodeIndices, equation_map);
        then tmp;

        case (BEquation.WHEN_EQUATION(), NBSolve.Status.EXPLICIT) algorithm
          (tmp, simCodeIndices) := createWhenBody(eqn.body, eqn.source, eqn.attr, simCodeIndices);
        then tmp;

        case (BEquation.IF_EQUATION(), NBSolve.Status.EXPLICIT) algorithm
          (branches, simCodeIndices) := createIfBody(eqn.body, {}, simCodeIndices, kind, simcode_map, equation_map);
          tmp := IF(simCodeIndices.equationIndex, listReverse(branches), eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case (BEquation.ALGORITHM(), NBSolve.Status.EXPLICIT) algorithm
          tmp := ALGORITHM(simCodeIndices.equationIndex, eqn.alg.statements, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        // ToDo: add all other cases!

        // fallback implicit solving
        case (_, NBSolve.Status.IMPLICIT) algorithm
          (tmp, simCodeIndices) := createImplicitEquation(var, eqn, simCodeIndices, kind, simcode_map, equation_map);
         then tmp;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with status " + Solve.statusString(status) + " for \n" + Equation.toString(eqn)});
        then fail();

      end match;
      UnorderedMap.add(Equation.getEqnName(Pointer.create(eqn)), blck, equation_map);
    end createEquation;

    function createImplicitEquation
      "Creates a single implicit equation"
      input BVariable.Variable var;
      input Equation eqn;
      output Block blck;
      input output SimCodeIndices simCodeIndices;
      input Partition.Kind kind;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      StrongComponent comp;
      Integer index;
    algorithm
      (comp, _, index)  := Tearing.implicit(
        comp        = StrongComponent.SINGLE_COMPONENT(Pointer.create(var), Pointer.create(eqn), NBSolve.Status.IMPLICIT),
        funcTree    = FunctionTreeImpl.EMPTY(),
        index       = simCodeIndices.implicitIndex,
        kind  = kind
      );
      simCodeIndices.implicitIndex := index;
      (blck, simCodeIndices) := fromStrongComponent(comp, simCodeIndices, kind, simcode_map, equation_map);
    end createImplicitEquation;

    function createWhenBody
      input WhenEquationBody body;
      output Block blck;
      input DAE.ElementSource source;
      input EquationAttributes attr;
      input output SimCodeIndices simCodeIndices;
    protected
      list<ComponentRef> conditions;
      list<WhenStatement> when_stmts;
      Option<WhenEquationBody> else_when;
      Block tmp;
      Option<Block> else_when_block;
      Integer index = simCodeIndices.equationIndex;
    algorithm
      simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
      (conditions, when_stmts, else_when) := WhenEquationBody.getBodyAttributes(body);
      if Util.isSome(else_when) then
        (tmp, simCodeIndices) := createWhenBody(Util.getOption(else_when), source, attr, simCodeIndices);
        else_when_block := SOME(tmp);
      else
        else_when_block := NONE();
      end if;
      blck := WHEN(index, false, conditions, when_stmts, else_when_block, source, attr);
    end createWhenBody;

    function createIfBody
      input IfEquationBody body;
      input output list<tuple<Expression, list<Block>>> branches;
      input output SimCodeIndices simCodeIndices;
      input Partition.Kind kind;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      list<StrongComponent> comps;
      Block blck;
      list<Block> blcks = {};
    algorithm
      comps := list(StrongComponent.fromSolvedEquationSlice(Slice.SLICE(eqn, {})) for eqn in body.then_eqns);
      for comp in listReverse(comps) loop
        (blck, simCodeIndices, _) := Block.fromStrongComponent(comp, simCodeIndices, kind, simcode_map, equation_map);
        blcks := blck :: blcks;
      end for;
      branches := (body.condition, blcks) :: branches;
      if Util.isSome(body.else_if) then
        (branches, simCodeIndices) := createIfBody(Util.getOption(body.else_if), branches, simCodeIndices, kind, simcode_map, equation_map);
      end if;
    end createIfBody;

    function createAlgorithm
      input Equation eqn;
      output Block blck;
      input output SimCodeIndices indices;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      list<Statement> stmts;
    algorithm
      stmts := match eqn
        case Equation.ALGORITHM() then eqn.alg.statements;
        else Equation.toStatement(eqn);
      end match;

      blck := ALGORITHM(indices.equationIndex, stmts, Equation.getAttributes(eqn));
      indices.equationIndex := indices.equationIndex + 1;
      UnorderedMap.add(Equation.getEqnName(Pointer.create(eqn)), blck, equation_map);
    end createAlgorithm;

    function createAssignment
      "Creates an assignment equation."
      input Equation eqn;
      output Block blck;
      input output SimCodeIndices simCodeIndices;
    algorithm
      blck := match eqn
        local
          Equation qual;
          Type ty;
          Operator operator;
          SimVar residualVar;
          ComponentRef cref;
          Expression lhs, rhs;
          Block tmp;

        case qual as BEquation.SCALAR_EQUATION(lhs = Expression.CREF(cref = cref))
          algorithm
            tmp := SIMPLE_ASSIGN(simCodeIndices.equationIndex, cref, qual.rhs, qual.source, qual.attr);
            simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case qual as BEquation.ARRAY_EQUATION(lhs = Expression.CREF(cref = cref))
          algorithm
            tmp := SIMPLE_ASSIGN(simCodeIndices.equationIndex, cref, qual.rhs, qual.source, qual.attr);
            simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        // ToDo: add all other cases!

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + Equation.toString(eqn)});
        then fail();

      end match;
    end createAssignment;

    function collectAlgebraicLoops
      input list<list<Block>> blcks;
      input output list<Block> linearLoops;
      input output list<Block> nonlinearLoops;
      input output list<SimJacobian> jacobians;
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    algorithm
      for blck_lst in blcks loop
        for blck in blck_lst loop
          (linearLoops, nonlinearLoops) := match blck
            local
              Option<SimJacobian> jacobian;
            case LINEAR() then (blck :: linearLoops, nonlinearLoops);
            case NONLINEAR() algorithm
              jacobian := NonlinearSystem.getJacobian(blck.system);
              if Util.isSome(jacobian) then
                jacobians := Util.getOption(jacobian) :: jacobians;
              end if;
              blck.system := NonlinearSystem.setJacobian(blck.system, jacobian);
            then (linearLoops, blck :: nonlinearLoops);
            else (linearLoops, nonlinearLoops);
          end match;
        end for;
      end for;
    end collectAlgebraicLoops;

    function convert
      input Block blck;
      output OldSimCode.SimEqSystem oldBlck;
    algorithm
      oldBlck := match blck
        local
          ComponentRef iter;
          Expression range, exp;
          list<tuple<DAE.ComponentRef, DAE.Exp>> old_iterators = {};
          list<Block> blcks;
          DAE.ComponentRef oldIter;
          DAE.Type oldType;
          DAE.Statement for_stmt;
          list<tuple<DAE.Exp, list<OldSimCode.SimEqSystem>>> oldBranches = {};
          list<OldSimCode.SimEqSystem> else_branch = {};

        case RESIDUAL()         then OldSimCode.SES_RESIDUAL(blck.index, blck.res_index, Expression.toDAE(blck.exp), blck.source, EquationAttributes.convert(blck.attr));
        case ARRAY_RESIDUAL()   then OldSimCode.SES_RESIDUAL(blck.index, blck.res_index, Expression.toDAE(blck.exp), blck.source, EquationAttributes.convert(blck.attr));
        case FOR_RESIDUAL() algorithm
          for iterator in listReverse(blck.iterators) loop
            (iter, range) := iterator;
            old_iterators := (ComponentRef.toDAE(iter), Expression.toDAE(range)) :: old_iterators;
          end for;
        then OldSimCode.SES_FOR_RESIDUAL(blck.index, blck.res_index, old_iterators, Expression.toDAE(blck.exp), blck.source, EquationAttributes.convert(blck.attr));
        case GENERIC_RESIDUAL() algorithm
          for iterator in listReverse(blck.iterators) loop
            (iter, range) := iterator;
            old_iterators := (ComponentRef.toDAE(iter), Expression.toDAE(range)) :: old_iterators;
          end for;
        then OldSimCode.SES_GENERIC_RESIDUAL(blck.index, blck.res_index, blck.scal_indices, old_iterators, Expression.toDAE(blck.exp), blck.source, EquationAttributes.convert(blck.attr));
        case SIMPLE_ASSIGN()    then OldSimCode.SES_SIMPLE_ASSIGN(blck.index, ComponentRef.toDAE(blck.lhs), Expression.toDAE(blck.rhs), blck.source, EquationAttributes.convert(blck.attr));
        case ARRAY_ASSIGN()     then OldSimCode.SES_ARRAY_CALL_ASSIGN(blck.index, Expression.toDAE(blck.lhs), Expression.toDAE(blck.rhs), blck.source, EquationAttributes.convert(blck.attr));
        case GENERIC_ASSIGN()   then OldSimCode.SES_GENERIC_ASSIGN(blck.index, blck.call_index, blck.scal_indices, blck.source, EquationAttributes.convert(blck.attr));
        case ENTWINED_ASSIGN()  then OldSimCode.SES_ENTWINED_ASSIGN(blck.index, blck.call_order, list(convert(single_call) for single_call in blck.single_calls), blck.source, EquationAttributes.convert(blck.attr));
        case IF() algorithm
          for branch in blck.branches loop
            (exp, blcks) := branch;
            if Expression.isEnd(exp) then
              if listEmpty(else_branch) then
                else_branch := list(convert(blck_) for blck_ in blcks);
              else
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there is
                  at least two non-conditional branches in:\n" + Block.toString(blck)});
                fail();
              end if;
            elseif listEmpty(else_branch) then
              oldBranches := (Expression.toDAE(exp), list(convert(blck_) for blck_ in blcks)) :: oldBranches;
            else
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there is a
                conditional branch after a non-conditional branch in:\n" + Block.toString(blck)});
              fail();
            end if;
          end for;
          if listEmpty(else_branch) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there "
              + "is no non-conditional branch in:\n" + Block.toString(blck)});
            fail();
          end if;
        then OldSimCode.SES_IFEQUATION(
          index = blck.index,
          ifbranches = listReverse(oldBranches),
          elsebranch = else_branch,
          source = blck.source,
          eqAttr = EquationAttributes.convert(blck.attr)
        );

        case WHEN() then OldSimCode.SES_WHEN(
          index       = blck.index,
          conditions  = list(ComponentRef.toDAE(cr) for cr in blck.conditions),
          initialCall = blck.initialCall,
          whenStmtLst = list(WhenStatement.convert(stmt) for stmt in blck.when_stmts),
          elseWhen    = Util.applyOption(blck.else_when, convert),
          source      = blck.source,
          eqAttr      = EquationAttributes.convert(blck.attr)
        );

        case NONLINEAR()        then OldSimCode.SES_NONLINEAR(NonlinearSystem.convert(blck.system), NONE(), EquationAttributes.convert(EquationAttributes.default(EquationKind.CONTINUOUS, false)) /* dangerous! */);

        case ALGORITHM()        then OldSimCode.SES_ALGORITHM(blck.index, ConvertDAE.convertStatements(blck.stmts), EquationAttributes.convert(blck.attr));

        case ALIAS() guard(blck.aliasOf > 0) then OldSimCode.SES_ALIAS(blck.index, blck.aliasOf);

        // ToDo: add all the other cases here!


        case ALIAS() guard(blck.aliasOf == -1) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for following alias block because the index has not been updated:\n" + toString(blck)});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(blck)});
        then fail();
      end match;
    end convert;

    function convertList
      input list<Block> blck_lst;
      output list<OldSimCode.SimEqSystem> oldBlck_lst = list(convert(blck) for blck in blck_lst);
    end convertList;

    function convertListList
      input list<list<Block>> blck_lst_lst;
      output list<list<OldSimCode.SimEqSystem>> oldBlck_lst_lst = list(convertList(blck_lst) for blck_lst in blck_lst_lst);
    end convertListList;

    function fixIndices
      input list<Block> blcks;
      input output list<Block> acc;
      input output SimCodeIndices indices;
    algorithm
      (acc, indices) := match blcks
        local
          Block blck;
          list<Block> rest;
        case blck :: rest algorithm
          (blck, indices) := fixIndex(blck, indices);
        then fixIndices(rest, blck :: acc, indices);
        else (acc, indices);
      end match;
    end fixIndices;

    function fixIndex
      input output Block blck;
      input output SimCodeIndices indices;
    algorithm
      blck := match blck
        local
          Block tmp;
          list<Block> tmp_lst;

        case RESIDUAL() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case ARRAY_RESIDUAL() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case SIMPLE_ASSIGN() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case ARRAY_ASSIGN() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case GENERIC_ASSIGN() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case ALIAS() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case ALGORITHM() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case INVERSE_ALGORITHM() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case IF() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
        then blck;

        case WHEN() algorithm
          blck.index := indices.equationIndex;
          indices.equationIndex := indices.equationIndex + 1;
          if Util.isSome(blck.else_when) then
            (tmp, indices) := fixIndex(Util.getOption(blck.else_when), indices);
            blck.else_when := SOME(tmp);
          end if;
        then blck;

        case LINEAR() algorithm
          // TODO (these are not really necessary i suppose)
        then blck;

        case NONLINEAR() algorithm
          // TODO (these are not really necessary i suppose)
        then blck;

        case HYBRID() algorithm
          (tmp, indices) := fixIndex(blck.continuous, indices);
          (tmp_lst, indices) := fixIndices(blck.discreteEqs, {}, indices);
          blck.continuous := tmp;
          blck.discreteEqs := tmp_lst;
        then blck;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(blck)});
        then fail();
      end match;
    end fixIndex;

    function collectEntwinedEquations
      "collects entwined equations from initial blocks"
      input Block blck;
      output list<Block> lst;
    algorithm
      lst := match blck
        case ENTWINED_ASSIGN() then blck.single_calls;
        else {};
      end match;
    end collectEntwinedEquations;
  protected
    function whenString
      input list<ComponentRef> conditions;
      input list<WhenStatement> when_stmts;
      input Option<Block> else_when;
      input output String str = "";
    protected
      String indent = str;
    algorithm
      str := "when " + List.toString(conditions, ComponentRef.toString) + "\n" +
             List.toString(when_stmts, function WhenStatement.toString(str = indent + "\t"), "", "", "\n", "") + "\n";
      if Util.isSome(else_when) then
        str := str + indent + "else" + toString(Util.getOption(else_when));
      else
        str := str + indent + "end when;\n";
      end if;
    end whenString;

    function getGenericAssignIndex
      input Block blck;
      output Integer index;
    algorithm
      index := match blck
        case GENERIC_ASSIGN() then blck.call_index;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(blck)});
        then fail();
      end match;
    end getGenericAssignIndex;

    function getGenericEquationName
      input StrongComponent comp;
      output ComponentRef name;
    algorithm
      name := match comp
        case StrongComponent.GENERIC_COMPONENT() then Equation.getEqnName(Slice.getT(comp.eqn));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + StrongComponent.toString(comp)});
        then fail();
      end match;
    end getGenericEquationName;
  end Block;

  uniontype LinearSystem
    record LINEAR_SYSTEM
      Integer index;
      Boolean mixed;
      Boolean torn;
      list<SimVar> vars;
      list<Expression> beqs; //ToDo what is this? binding expressions?
      list<tuple<Integer, Integer, Block>> simJac; // ToDo: is this the old jacobian structure?
      /* solver linear tearing system */
      list<Block> residual;
      Option<SimJacobian> jacobian;
      list<DAE.ElementSource> sources;
      Integer indexSystem;
      Integer size "Number of variables that are solved in this system. Needed because 'crefs' only contains the iteration variables.";
      Boolean partOfJac "if TRUE then this system is part of a jacobian matrix";
    end LINEAR_SYSTEM;

    function toString
      input LinearSystem system;
      input output String str;
    algorithm
      str := "Linear System (size = " + intString(system.size) + ", jacobian = " + boolString(system.partOfJac) + ", mixed = " + boolString(system.mixed) + ", torn = " + boolString(system.torn) + ")\n" + Block.listToString(system.residual, str + "--");
    end toString;

/* ToDo: fix this
    function convert
      input LinearSystem system;
      output OldSimCode.LinearSystem oldSystem;
    protected
      list<DAE.Exp> beqs = {};
    algorithm
      for beq in system.beqs loop
        beqs := Expression.toDAE(beq) :: beqs;
      end for;
      oldSystem := OldSimCode.LINEARSYSTEM(
        index                 = system.index,
        partOfMixed           = system.mixed,
        tornSystem            = system.torn,
        vars                  = SimVar.convertList(system.vars),
        beqs                  = listReverse(beqs),
        indexNonLinearSystem  = system.indexSystem,
        nUnknowns             = system.size,
        jacobianMatrix        = NONE(), // ToDo update this!
        homotopySupport       = system.homotopy,
        clockIndex            = NONE() // ToDo update this
        );
    end convert;
*/
  end LinearSystem;

  uniontype NonlinearSystem
    record NONLINEAR_SYSTEM
      Integer index;
      list<Block> blcks;
      list<ComponentRef> crefs;
      Integer indexSystem;
      Integer size "Number of variables that are solved in this system. Needed because 'crefs' only contains the iteration variables.";
      Pointer<Option<SimJacobian>> jacobian;
      Boolean homotopy;
      Boolean mixed;
      Boolean torn;
    end NONLINEAR_SYSTEM;

    function getJacobian
      input NonlinearSystem syst;
      output Option<SimJacobian> jacobian = Pointer.access(syst.jacobian);
    end getJacobian;

    function setJacobian
      input output NonlinearSystem syst;
      input Option<SimJacobian> jacobian;
    algorithm
      Pointer.update(syst.jacobian, jacobian);
    end setJacobian;

    function toString
      input NonlinearSystem system;
      input output String str;
    algorithm
      str := "Nonlinear System (size = " + intString(system.size) + ", homotopy = " + boolString(system.homotopy)
              + ", mixed = " + boolString(system.mixed) + ", torn = " + boolString(system.torn) + ")\n"
              + str + "--" + List.toString(system.crefs, ComponentRef.toString, "Iteration Vars:", "{", ", ", "}", true, 10) + "\n"
              + Block.listToString(system.blcks, str + "--");
    end toString;

    function convert
      input NonlinearSystem system;
      output OldSimCode.NonlinearSystem oldSystem;
    protected
      list<DAE.ComponentRef> crefs = {};
    algorithm
      for cref in system.crefs loop
        crefs := ComponentRef.toDAE(cref) :: crefs;
      end for;
      oldSystem := OldSimCode.NONLINEARSYSTEM(
        index                 = system.index,
        eqs                   = Block.convertList(system.blcks),
        crefs                 = listReverse(crefs),
        indexNonLinearSystem  = system.indexSystem,
        nUnknowns             = system.size,
        jacobianMatrix        = Util.applyOption(Pointer.access(system.jacobian), SimJacobian.convert), // ToDo update this!
        homotopySupport       = system.homotopy,
        mixedSystem           = system.mixed,
        tornSystem            = system.torn,
        clockIndex            = NONE() // ToDo update this
        );
    end convert;
  end NonlinearSystem;

  annotation(__OpenModelica_Interface="backend");
end NSimStrongComponent;
