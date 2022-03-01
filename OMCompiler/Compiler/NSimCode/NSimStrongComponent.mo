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
  import BackendExtension = NFBackendExtension;
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import Expression = NFExpression;
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import InstNode = NFInstNode.InstNode;
  import Operator = NFOperator;
  import Statement = NFStatement;
  import Type = NFType;
  import Variable = NFVariable;

  // old backend imports
  import OldBackendDAE = BackendDAE;

  // Backend imports
  import AliasInfo = NBStrongComponent.AliasInfo;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationAttributes, EquationKind, EquationPointer, EquationPointers, WhenEquationBody, WhenStatement, SlicingStatus};
  import BVariable = NBVariable;
  import Jacobian = NBJacobian;
  import Solve = NBSolve;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import Tearing = NBTearing;

  // Old SimCode imports
  import OldSimCode = SimCode;

  // SimCode imports
  import SimCode = NSimCode;
  import NSimJacobian.SimJacobian;
  import NSimVar.{SimVar, SimVars, VarType};

  // Util imports
  import Error;
  import Slice = NBSlice;

public
  uniontype Block
    "A single blck from BLT transformation."

    record RESIDUAL
      "Single residual equation of the form
      0 = exp"
      Integer index;
      Expression exp;
      DAE.ElementSource source;
      EquationAttributes attr;
    end RESIDUAL;

    record ARRAY_RESIDUAL
      "Single residual array equation of the form
      0 = exp. Structurally equal to RESIDUAL, but the destinction is important
      for code generation."
      Integer index;
      Expression exp;
      DAE.ElementSource source;
      EquationAttributes attr;
    end ARRAY_RESIDUAL;

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
      BEquation.IfEquationBody body;
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
        case SIMPLE_ASSIGN()      then str + "(" + intString(blck.index) + ") " + ComponentRef.toString(blck.lhs) + " := " + Expression.toString(blck.rhs) + "\n";
        case ARRAY_ASSIGN()       then str + "(" + intString(blck.index) + ") " + Expression.toString(blck.lhs) + " := " + Expression.toString(blck.rhs) + "\n";
        case ALIAS()              then str + "(" + intString(blck.index) + ") Alias of " + intString(blck.aliasOf) + "\n";
        case ALGORITHM()          then str + "(" + intString(blck.index) + ") Algorithm\n" + Statement.toStringList(blck.stmts, str) + "\n";
        case INVERSE_ALGORITHM()  then str + "(" + intString(blck.index) + ") Inverse Algorithm\n" + Statement.toStringList(blck.stmts, str) + "\n";
        case IF()                 then str + BEquation.IfEquationBody.toString(blck.body, str + "    ", "(" + intString(blck.index) + ") ") + "\n";
        case WHEN()               then str + "(" + intString(blck.index) + ") " + whenString(blck.conditions, blck.when_stmts, blck.else_when);
        case LINEAR()             then str + "(" + intString(blck.system.index) + ") " + LinearSystem.toString(blck.system, str);
        case NONLINEAR()          then str + "(" + intString(blck.system.index) + ") " + NonlinearSystem.toString(blck.system, str);
        case HYBRID()             then str + "(" + intString(blck.index) + ") Hybrid\n"; // ToDo!
                                  else getInstanceName() + " failed.\n";
      end match;
    end toString;

    function getIndex
      input Block blck;
      output Integer index;
    algorithm
      index := match blck
        case RESIDUAL()           then blck.index;
        case ARRAY_RESIDUAL()     then blck.index;
        case SIMPLE_ASSIGN()      then blck.index;
        case ARRAY_ASSIGN()       then blck.index;
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
        case RESIDUAL(attr = attr)           then EquationKind.isDiscrete(attr.kind);
        case ARRAY_RESIDUAL(attr = attr)     then EquationKind.isDiscrete(attr.kind);
        case SIMPLE_ASSIGN(attr = attr)      then EquationKind.isDiscrete(attr.kind);
        case ARRAY_ASSIGN(attr = attr)       then EquationKind.isDiscrete(attr.kind);
        case ALIAS()                         then false; // todo: once this is implemented check in the HT for alias eq discrete
        case ALGORITHM(attr = attr)          then EquationKind.isDiscrete(attr.kind);
        case INVERSE_ALGORITHM(attr = attr)  then EquationKind.isDiscrete(attr.kind);
        case IF(attr = attr)                 then EquationKind.isDiscrete(attr.kind);
        case WHEN(attr = attr)               then EquationKind.isDiscrete(attr.kind); // should hopefully always be true
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
      input list<System.System> systems;
      output list<list<Block>> blcks = {};
      input output list<Block> all_blcks;
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      list<Block> tmp;
    algorithm
      for system in systems loop
        (tmp, simCodeIndices) := fromSystem(system, simCodeIndices, simcode_map);
        blcks := tmp :: blcks;
        all_blcks := listAppend(tmp, all_blcks);
      end for;
      blcks := listReverse(blcks);
    end createBlocks;

    function createDiscreteBlocks
      input list<System.System> systems;
      input output list<list<Block>> blcks;
      input output list<Block> all_blcks;
      input output list<Block> event_dependencies;
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      list<Block> tmp;
    algorithm
      for system in systems loop
        (tmp, simCodeIndices) := fromSystem(system, simCodeIndices, simcode_map);
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
      input list<System.System> systems;
      output list<Block> blcks;
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      list<Block> tmp;
      list<list<Block>> tmp_lst = {};
    algorithm
      for system in systems loop
        (tmp, simCodeIndices) := fromSystem(system, simCodeIndices, simcode_map);
        tmp_lst := tmp :: tmp_lst;
      end for;
      blcks := List.flatten(tmp_lst);
    end createInitialBlocks;

    function createDAEModeBlocks
      input list<System.System> systems;
      output list<list<Block>> blcks = {};
      output list<SimVar> vars = {};
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      Pointer<SimCode.SimCodeIndices> indices_ptr = Pointer.create(simCodeIndices);
      Pointer<list<SimVar>> vars_ptr = Pointer.create({});
      list<Block> tmp;
    algorithm
      for system in listReverse(systems) loop
        BVariable.VariablePointers.map(system.unknowns, function SimVar.traverseCreate(acc = vars_ptr, indices_ptr = indices_ptr, varType = VarType.RESIDUAL));
        (tmp, simCodeIndices) := fromSystem(system, Pointer.access(indices_ptr), simcode_map);
        blcks := tmp :: blcks;
      end for;
      vars := listReverse(Pointer.access(vars_ptr));
    end createDAEModeBlocks;

    function createNoReturnBlocks
      input EquationPointers equations;
      output list<Block> blcks = {};
      input output SimCode.SimCodeIndices simCodeIndices;
      input System.SystemType systemType;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
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
            then createEquation(NBVariable.getVar(cref), eqn, NBSolve.Status.EXPLICIT, simCodeIndices, systemType, simcode_map);


            case Equation.WHEN_EQUATION()
            then createEquation(NBVariable.DUMMY_VARIABLE, eqn, NBSolve.Status.EXPLICIT, simCodeIndices, systemType, simcode_map);

            /* ToDo: ARRAY_EQUATION ... */

            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + Equation.toString(eqn)});
            then fail();
          end match;

          blcks := tmp :: blcks;
          // list reverse necessary? they are unodered anyway
        end if;
      end for;
    end createNoReturnBlocks;

    function fromSystem
      input System.System system;
      output list<Block> blcks;
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    algorithm
      blcks := match system.strongComponents
        local
          array<StrongComponent> comps;
          Block tmp;
          list<Block> result = {};
          Integer index;

        case SOME(comps)
          algorithm
            for i in 1:arrayLength(comps) loop
              (tmp, simCodeIndices, index) := fromStrongComponent(comps[i], simCodeIndices, system.systemType, simcode_map);
              // add it to the alias map (before creating because of index bump)
              UnorderedMap.add(AliasInfo.ALIAS_INFO(system.systemType, system.partitionIndex, i), index, simCodeIndices.alias_map);
              result := tmp :: result;
            end for;
        then listReverse(result);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + System.System.toString(system)});
        then fail();
      end match;
    end fromSystem;

    function fromStrongComponent
      input StrongComponent comp;
      output Block blck;
      input output SimCode.SimCodeIndices simCodeIndices;
      output Integer index;
      input System.SystemType systemType;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
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
          list<Statement> stmts = {};
          SlicingStatus status;
          ComponentRef var_cref;
          Integer aliasOf;
          list<Integer> eqn_indices, sizes;
          list<Equation> entwined_eqns = {};
          UnorderedMap<ComponentRef, Expression> replacements;

        case StrongComponent.SINGLE_EQUATION() algorithm
          (tmp, simCodeIndices) := createEquation(Pointer.access(comp.var), Pointer.access(comp.eqn), comp.status, simCodeIndices, systemType, simcode_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.SINGLE_ARRAY() algorithm
          (tmp, simCodeIndices) := createEquation(Pointer.access(comp.var), Pointer.access(comp.eqn), comp.status, simCodeIndices, systemType, simcode_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.SLICED_EQUATION() guard(Equation.isForEquation(Slice.getT(comp.eqn))) algorithm
          eqn := Pointer.access(Slice.getT(comp.eqn));
          stmts := {Equation.toStatement(eqn)};
          tmp := ALGORITHM(simCodeIndices.equationIndex, stmts, Equation.getAttributes(eqn));
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then (tmp, getIndex(tmp));

        case StrongComponent.SLICED_EQUATION() algorithm
          // just a regular equation solved for a sliced variable
          // use cref instead of var because it has subscripts!
          eqn := Pointer.access(Slice.getT(comp.eqn));
          (tmp, simCodeIndices) := createEquation(Variable.fromCref(comp.var_cref), eqn, comp.status, simCodeIndices, systemType, simcode_map);
        then (tmp, getIndex(tmp));

        case StrongComponent.TORN_LOOP(strict = strict)algorithm
          for i in 1:arrayLength(strict.innerEquations) loop
            (tmp, simCodeIndices) := fromInnerEquation(strict.innerEquations[i], simCodeIndices, systemType, simcode_map);
            eqns := tmp :: eqns;
          end for;
          for slice in strict.residual_eqns loop
            (tmp, simCodeIndices) := createResidual(Pointer.access(Slice.getT(slice)), simCodeIndices);
            eqns := tmp :: eqns;
          end for;
          for var_ptr in strict.iteration_vars loop
            var := Pointer.access(var_ptr);
            // This does not seem to be correct
            //var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.LOOP_ITERATION());
            Pointer.update(var_ptr, var);
            crefs := var.name :: crefs;
          end for;

          // reactivate this once nonlinear loops actually work
          if Util.isSome(strict.jac) and false then
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
          if UnorderedMap.contains(comp.aliasInfo, simCodeIndices.alias_map) then
            aliasOf := UnorderedMap.getSafe(comp.aliasInfo, simCodeIndices.alias_map);
          else
            aliasOf := -1;
          end if;
          tmp := ALIAS(simCodeIndices.equationIndex, comp.aliasInfo, aliasOf);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then (tmp, getIndex(tmp));

        case StrongComponent.ENTWINED_EQUATION() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because entwined equations have to be resolved beforehand in Solve.solve(). Failed for:\n"
            + StrongComponent.toString(comp)});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with unknown reason for \n" + StrongComponent.toString(comp)});
        then fail();
      end match;
    end fromStrongComponent;

    function fromInnerEquation
      input BEquation.InnerEquation innerEqn;
      output Block blck;
      input output SimCode.SimCodeIndices simCodeIndices;
      input System.SystemType systemType;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    algorithm
      blck := match innerEqn
        case BEquation.InnerEquation.INNER_EQUATION()
          algorithm
            (blck, simCodeIndices) := createEquation(Pointer.access(innerEqn.var), Pointer.access(innerEqn.eqn), NBSolve.Status.EXPLICIT, simCodeIndices, systemType, simcode_map);
        then blck;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + Equation.toString(Pointer.access(innerEqn.eqn))});
        then fail();
      end match;
    end fromInnerEquation;

    function createResidual
      input Equation eqn;
      output Block blck;
      input output SimCode.SimCodeIndices simCodeIndices;
    algorithm
      blck := match eqn
        local
          Type ty;
          Operator operator;
          Expression lhs, rhs;
          Block tmp;
          Equation forEqn;

        case BEquation.SCALAR_EQUATION() algorithm
          tmp := RESIDUAL(simCodeIndices.equationIndex, eqn.rhs, eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case BEquation.ARRAY_EQUATION() algorithm
          tmp := ARRAY_RESIDUAL(simCodeIndices.equationIndex, eqn.rhs, eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case BEquation.SIMPLE_EQUATION() algorithm
          ty := ComponentRef.getComponentType(eqn.lhs);
          if Type.isArray(ty) then
            tmp := ARRAY_RESIDUAL(simCodeIndices.equationIndex, Expression.fromCref(eqn.rhs), eqn.source, eqn.attr);
          else
            tmp := RESIDUAL(simCodeIndices.equationIndex, Expression.fromCref(eqn.rhs), eqn.source, eqn.attr);
          end if;
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        /* this needs more thought
        case BEquation.FOR_EQUATION() algorithm
          rhs := BEquation.getResidualExp(eqn);
          lhs := Expression.makeZero(
          forEqn :=
          eqn := Equation.splitIterators(eqn);
          // handle these as if they were algorithms
          stmt := Equation.toStatement(eqn);

        then tmp;
        */
        case BEquation.FOR_EQUATION() algorithm
          rhs := Equation.getRHS(eqn);
          lhs := Expression.makeZero(Expression.typeOf(rhs));
          tmp := RESIDUAL(simCodeIndices.equationIndex, lhs, eqn.source, eqn.attr);
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        // ToDo: add all other cases!

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + Equation.toString(eqn)});
        then fail();

      end match;
    end createResidual;

    function createEquation
      "Creates a single equation"
      input Variable var;
      input Equation eqn;
      input Solve.Status status;
      output Block blck;
      input output SimCode.SimCodeIndices simCodeIndices;
      input System.SystemType systemType;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    algorithm
      blck := match (eqn, status)
        local
          Type ty;
          Operator operator;
          Expression lhs, rhs;
          Block tmp;

        case (BEquation.SCALAR_EQUATION(), NBSolve.Status.EXPLICIT)
          algorithm
            tmp := SIMPLE_ASSIGN(simCodeIndices.equationIndex, var.name, eqn.rhs, eqn.source, eqn.attr);
            simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case (BEquation.ARRAY_EQUATION(), NBSolve.Status.EXPLICIT)
          algorithm
            tmp := ARRAY_ASSIGN(simCodeIndices.equationIndex, Expression.fromCref(var.name), eqn.rhs, eqn.source, eqn.attr);
            simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        // remove simple equations should remove this, but if it is not activated we need this
        case (BEquation.SIMPLE_EQUATION(), NBSolve.Status.EXPLICIT)
          algorithm
            ty := ComponentRef.getComponentType(eqn.lhs);
            if Type.isArray(ty) then
              tmp := ARRAY_ASSIGN(simCodeIndices.equationIndex, Expression.fromCref(var.name), Expression.fromCref(eqn.rhs), eqn.source, eqn.attr);
            else
              tmp := SIMPLE_ASSIGN(simCodeIndices.equationIndex, var.name, Expression.fromCref(eqn.rhs), eqn.source, eqn.attr);
            end if;
            simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then tmp;

        case (BEquation.WHEN_EQUATION(), NBSolve.Status.EXPLICIT) algorithm
          (tmp, simCodeIndices) := createWhenBody(eqn.body, simCodeIndices, eqn.source, eqn.attr);
        then tmp;

        // ToDo: add all other cases!

        // fallback implicit solving
        case (_, NBSolve.Status.IMPLICIT)
          algorithm
            (tmp, simCodeIndices) := createImplicitEquation(var, eqn, simCodeIndices, systemType, simcode_map);
         then tmp;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with status " + Solve.statusString(status) + " for \n" + Equation.toString(eqn)});
        then fail();

      end match;
    end createEquation;

    function createImplicitEquation
      "Creates a single implicit equation"
      input BVariable.Variable var;
      input Equation eqn;
      output Block blck;
      input output SimCode.SimCodeIndices simCodeIndices;
      input System.SystemType systemType;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      StrongComponent comp;
      Integer index;
    algorithm
      (comp, _, index)  := Tearing.implicit(
        comp        = StrongComponent.SINGLE_EQUATION(Pointer.create(var), Pointer.create(eqn), NBSolve.Status.IMPLICIT),
        funcTree    = FunctionTreeImpl.EMPTY(),
        index       = simCodeIndices.implicitIndex,
        systemType  = systemType
      );
      simCodeIndices.implicitIndex := index;
      (blck, simCodeIndices) := fromStrongComponent(comp, simCodeIndices, systemType, simcode_map);
    end createImplicitEquation;

    function createWhenBody
      input WhenEquationBody body;
      output Block blck;
      input output SimCode.SimCodeIndices simCodeIndices;
      input DAE.ElementSource source;
      input EquationAttributes attr;
    protected
      list<ComponentRef> conditions;
      list<WhenStatement> when_stmts;
      Option<WhenEquationBody> else_when;
      Block tmp;
      Option<Block> else_when_block;
    algorithm
      (conditions, when_stmts, else_when) := WhenEquationBody.getBodyAttributes(body);
      if Util.isSome(else_when) then
        (tmp, simCodeIndices) := createWhenBody(Util.getOption(else_when), simCodeIndices, source, attr);
        else_when_block := SOME(tmp);
      else
        else_when_block := NONE();
      end if;
      blck := WHEN(simCodeIndices.equationIndex, false, conditions, when_stmts, else_when_block, source, attr);
      simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
    end createWhenBody;

    function traverseCreateEquation
      "Only works, if the variable to solve for is already isolated in the LHS!"
      input output Equation eqn;
      input Pointer<list<Block>> acc;
      input Pointer<SimCode.SimCodeIndices> indices_ptr;
      input System.SystemType systemType;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      Variable var;
      Block blck;
      SimCode.SimCodeIndices indices;
    algorithm
      try
        var := BVariable.getVar(Expression.toCref(Equation.getLHS(eqn)));
        (blck, indices) := createEquation(var, eqn, NBSolve.Status.EXPLICIT, Pointer.access(indices_ptr), systemType, simcode_map);
        Pointer.update(acc, blck :: Pointer.access(acc));
        Pointer.update(indices_ptr, indices);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + Equation.toString(eqn)});
        fail();
      end try;
    end traverseCreateEquation;

    function traverseCreateResidual
      "Only works, if the variable to solve for is saved in equation attributes!
      used for dae mode jacobians."
      input output Equation eqn;
      input Pointer<list<Block>> acc;
      input Pointer<SimCode.SimCodeIndices> indices_ptr;
    protected
      Block blck;
      SimCode.SimCodeIndices indices;
    algorithm
      try
        (blck, indices) := createResidual(eqn, Pointer.access(indices_ptr));
        Pointer.update(acc, blck :: Pointer.access(acc));
        Pointer.update(indices_ptr, indices);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + Equation.toString(eqn)});
        fail();
      end try;
    end traverseCreateResidual;

    function createAssignment
      "Creates an assignment equation."
      input Equation eqn;
      output Block blck;
      input output SimCode.SimCodeIndices simCodeIndices;
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

        // remove simple equations should remove this, but if it is not activated we need this
        case qual as BEquation.SIMPLE_EQUATION()
          algorithm
            tmp := SIMPLE_ASSIGN(simCodeIndices.equationIndex, qual.lhs, Expression.fromCref(qual.rhs), qual.source, qual.attr);
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
      input output SimCode.SimCodeIndices simCodeIndices;
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
          Expression range;
          DAE.ComponentRef oldIter;
          DAE.Type oldType;
          DAE.Statement for_stmt;

        case RESIDUAL()         then OldSimCode.SES_RESIDUAL(blck.index, Expression.toDAE(blck.exp), blck.source, EquationAttributes.convert(blck.attr));
        case ARRAY_RESIDUAL()   then OldSimCode.SES_RESIDUAL(blck.index, Expression.toDAE(blck.exp), blck.source, EquationAttributes.convert(blck.attr));
        case SIMPLE_ASSIGN()    then OldSimCode.SES_SIMPLE_ASSIGN(blck.index, ComponentRef.toDAE(blck.lhs), Expression.toDAE(blck.rhs), blck.source, EquationAttributes.convert(blck.attr));
        case ARRAY_ASSIGN()     then OldSimCode.SES_ARRAY_CALL_ASSIGN(blck.index, Expression.toDAE(blck.lhs), Expression.toDAE(blck.rhs), blck.source, EquationAttributes.convert(blck.attr));
        case WHEN() then OldSimCode.SES_WHEN(
          index       = blck.index,
          conditions  = list(ComponentRef.toDAE(cr) for cr in blck.conditions),
          initialCall = blck.initialCall,
          whenStmtLst = list(WhenStatement.convert(stmt) for stmt in blck.when_stmts),
          elseWhen    = convertOpt(blck.else_when),
          source      = blck.source,
          eqAttr      = EquationAttributes.convert(blck.attr)
        );

        case NONLINEAR()        then OldSimCode.SES_NONLINEAR(NonlinearSystem.convert(blck.system), NONE(), EquationAttributes.convert(NBEquation.EQ_ATTR_DEFAULT_UNKNOWN) /* dangerous! */);

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

    function convertOpt
      input Option<Block> blck;
      output Option<OldSimCode.SimEqSystem> oldBlck = if Util.isSome(blck) then SOME(convert(Util.getOption(blck))) else NONE();
    end convertOpt;

    function convertList
      input list<Block> blck_lst;
      output list<OldSimCode.SimEqSystem> oldBlck_lst = {};
    algorithm
      for blck in blck_lst loop
        oldBlck_lst := convert(blck) :: oldBlck_lst;
      end for;
      oldBlck_lst := listReverse(oldBlck_lst);
    end convertList;

    function convertListList
      input list<list<Block>> blck_lst_lst;
      output list<list<OldSimCode.SimEqSystem>> oldBlck_lst_lst = {};
    algorithm
      for blck_lst in blck_lst_lst loop
        oldBlck_lst_lst := convertList(blck_lst) :: oldBlck_lst_lst;
      end for;
      oldBlck_lst_lst := listReverse(oldBlck_lst_lst);
    end convertListList;

    function fixIndices
      input list<Block> blcks;
      input output list<Block> acc;
      input output SimCode.SimCodeIndices indices;
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
      input output SimCode.SimCodeIndices indices;
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
      end match;
    end fixIndex;

  protected
    function whenString
      input list<ComponentRef> conditions;
      input list<WhenStatement> when_stmts;
      input Option<Block> else_when;
      output String str = "";
    algorithm
      str := "when " + List.toString(conditions, ComponentRef.toString) + "\n" +
             List.toString(when_stmts, function WhenStatement.toString(str = "\t"), "", "", "\n") + "\n";
      if Util.isSome(else_when) then
        str := str + "else" + toString(Util.getOption(else_when));
      else
        str := str + "end when;";
      end if;
    end whenString;
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
        jacobianMatrix        = SimJacobian.convertOpt(Pointer.access(system.jacobian)), // ToDo update this!
        homotopySupport       = system.homotopy,
        mixedSystem           = system.mixed,
        tornSystem            = system.torn,
        clockIndex            = NONE() // ToDo update this
        );
    end convert;
  end NonlinearSystem;

  annotation(__OpenModelica_Interface="backend");
end NSimStrongComponent;
