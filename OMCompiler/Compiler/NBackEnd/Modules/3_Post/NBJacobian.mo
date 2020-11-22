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
encapsulated package NBJacobian
"file:        NBJacobian.mo
 package:     NBJacobian
 description: This file contains the functions to create and manipulate jacobians.
              The main type is inherited from NBackendDAE.mo
              NOTE: There is no real jacobian type, it is a BackendDAE.
"

public
  import BackendDAE = NBackendDAE;
  import Module = NBModule;

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;

  // Backend imports
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import HashTableCrToCr = NBHashTableCrToCr;
  import HashTableCrToCrLst = NBHashTableCrToCrLst;
  import Jacobian = NBackendDAE.BackendDAE;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;

  // Util imports
  import AvlSetPath;
  import StringUtil;
  import Util;

public
  function main
    "Wrapper function for any jacobian function. This will be called during
     simulation and gets the corresponding subfunction from Config."
    extends Module.wrapper;
    input System.SystemType systemType;
  protected
    constant Module.jacobianInterface func = getModule();
  algorithm
    bdae := match bdae
      local
        String name                                     "Context name for jacobian";
        BVariable.VariablePointers knowns               "Variable array of knowns";
        Option<Jacobian> jacobian                       "Resulting jacobian";
        FunctionTree funcTree                           "Function call bodies";
        list<System.System> oldSystems, newSystems = {} "Equation systems before and afterwards";

      case BackendDAE.BDAE(varData = BVariable.VAR_DATA_SIM(knowns = knowns), funcTree = funcTree)
        algorithm
          (oldSystems, name) := match systemType
            case NBSystem.SystemType.ODE    then (bdae.ode, "ODEJac");
            case NBSystem.SystemType.INIT   then (bdae.ode, "INITJac");
            case NBSystem.SystemType.PARAM  then (bdae.param, "PARAMJac");
            case NBSystem.SystemType.DAE    then (Util.getOption(bdae.dae), "DAEJac");
            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + System.System.systemTypeString(systemType)});
            then fail();
          end match;

          // kabdelhak: i would really like these names, but for now we need A, B, C, D
          name := "A";

          for syst in oldSystems loop
            (jacobian, funcTree) := match syst
              case System.SYSTEM() then func(name, syst.unknowns, syst.daeUnknowns, syst.equations, knowns, syst.strongComponents, funcTree);
            end match;
            syst.jacobian := jacobian;
            newSystems := syst::newSystems;
          end for;
          newSystems := listReverse(newSystems);

          _ := match systemType
            case NBSystem.SystemType.ODE    algorithm bdae.ode    := newSystems;        then ();
            case NBSystem.SystemType.INIT   algorithm bdae.init   := newSystems;        then ();
            case NBSystem.SystemType.PARAM  algorithm bdae.param  := newSystems;        then ();
            case NBSystem.SystemType.DAE    algorithm bdae.dae    := SOME(newSystems);  then ();
          end match;
          bdae.funcTree := funcTree;
      then bdae;

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + BackendDAE.toString(bdae)});
      then fail();

    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.jacobianInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.JACOBIAN)
  algorithm
    (func) := match flag
      case "default"  then (jacobianSymbolic);
      case "symbolic" then (jacobianSymbolic);
      case "numeric"  then (jacobianNumeric);
      /* ... New jacobian modules have to be added here */
      else fail();
    end match;
  end getModule;

  type SparsityPatternCol = tuple<ComponentRef, list<ComponentRef>> "residual, {independents}";
  type SparsityPatternRow = SparsityPatternCol                      "independent, {residuals}";

  uniontype SparsityPattern
    record SPARSITY_PATTERN
      list<SparsityPatternCol> col_wise_pattern   "colum-wise sparsity pattern";
      list<SparsityPatternRow> row_wise_pattern   "row-wise sparsity pattern";
      list<ComponentRef> independent_vars         "independent variables solved here";
      list<ComponentRef> residual_vars            "residual vars e.g. $RES_DAE_0";
      Integer nnz                                 "number of nonzero elements";
    end SPARSITY_PATTERN;

    function toString
      input SparsityPattern pattern;
      input SparsityColoring coloring;
      output String str = StringUtil.headline_3("Sparsity Pattern (nnz: " + intString(pattern.nnz) + ")");
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
    algorithm
      if not listEmpty(pattern.col_wise_pattern) then
        for col in pattern.col_wise_pattern loop
          (cref, dependencies) := col;
          str := str + "(" + ComponentRef.toString(cref) + ")\t" + ComponentRef.listToString(dependencies) + "\n";
        end for;
      else
        str := str + "<empty sparsity pattern>\n";
      end if;
      str := str + "\n" + StringUtil.headline_3("Sparsity Coloring Groups");
      if not listEmpty(coloring) then
        for group in coloring loop
          str := str + ComponentRef.listToString(group) + "\n";
        end for;
      else
        str := str + "<empty sparsity coloring>\n";
      end if;
    end toString;

    function create
      input BVariable.VariablePointers independentVars;
      input BVariable.VariablePointers residualVars;
      input BEquation.EquationPointers equations;
      input Option<array<StrongComponent>> strongComponents "Strong Components";
      output SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring;
    algorithm
      sparsityPattern := match strongComponents
        local
          array<StrongComponent> comps;
          list<ComponentRef> independent_vars, residual_vars, tmp;
          HashTableCrToCrLst.HashTable ht;
          list<SparsityPatternCol> cols = {};
          list<SparsityPatternRow> rows = {};
          Integer nnz = 0;

        case SOME(comps) guard(arrayEmpty(comps)) algorithm
        then EMPTY_SPARSITY_PATTERN;

        case SOME(comps) algorithm
          // get all relevant crefs
          residual_vars := BVariable.VariablePointers.getVarNames(residualVars);
          independent_vars := BVariable.VariablePointers.getVarNames(independentVars);

          // create a sufficiant big hash table
          ht := HashTableCrToCrLst.empty(listLength(independent_vars) + listLength(residual_vars));

          // save all relevant crefs to know later on if a cref should be added
          for var in independent_vars loop
            ht := BaseHashTable.add((var, {}), ht);
          end for;
          for var in residual_vars loop
            ht := BaseHashTable.add((var, {}), ht);
          end for;

          // traverse all components and save cref dependencies (only column-wise)
          for i in 1:arrayLength(comps) loop
            ht := StrongComponent.getDependentCrefs(comps[i], ht);
          end for;

          // create row-wise sparsity pattern
          for cref in residual_vars loop
            tmp := List.unique(BaseHashTable.get(cref, ht));
            rows := (cref, tmp) :: rows;
            for dep in tmp loop
              // also add inverse dependency (indep var) --> (res/tmp) :: rest
              BaseHashTable.update((dep, cref :: BaseHashTable.get(dep, ht)), ht);
            end for;
          end for;

          // create column-wise sparsity pattern
          for cref in independent_vars loop
            cols := (cref, List.unique(BaseHashTable.get(cref, ht))) :: cols;
          end for;

          // find number of nonzero elements
          for col in cols loop
            (_, tmp) := col;
            nnz := nnz + listLength(tmp);
          end for;
        then SPARSITY_PATTERN(cols, rows, independent_vars, residual_vars, nnz);

        case NONE() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing strong components."});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();

      end match;

      // create coloring
      sparsityColoring := createEmptyColoring(sparsityPattern);
    end create;

    function createEmpty
      output SparsityPattern sparsityPattern = EMPTY_SPARSITY_PATTERN;
      output SparsityColoring sparsityColoring = createEmptyColoring(sparsityPattern);
    end createEmpty;

    function createEmptyColoring
      "creates an empty coloring that just groups each independent variable individually"
      input SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring = {};
    algorithm
      sparsityColoring := list({cref} for cref in sparsityPattern.independent_vars);
    end createEmptyColoring;

  end SparsityPattern;

  constant SparsityPattern EMPTY_SPARSITY_PATTERN = SPARSITY_PATTERN({}, {}, {}, {}, 0);

  type SparsityColoring = list<list<ComponentRef>>  "list of independent variable groups belonging to the same color";

protected
  function jacobianSymbolic extends Module.jacobianInterface;
  protected
    BVariable.VariablePointers seedCandidates, partialCandidates, residuals;
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> residual_vars_ptr = Pointer.create({});
    Pointer<Integer> idx = Pointer.create(0);
    Pointer<HashTableCrToCr.HashTable> jacobianHT = Pointer.create(HashTableCrToCr.empty());
    Differentiate.DifferentiationArguments diffArguments;

    BEquation.EquationPointers diffedEquations;
    BEquation.EqData eqDataJac;

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars;
    BVariable.VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;
  algorithm
    // ToDo: apply tearing to split residual/inner variables and equations
    // add inner / tmp cref tuples to HT
    (seedCandidates, partialCandidates) := if isSome(daeUnknowns) then (Util.getOption(daeUnknowns), unknowns) else (unknowns, BVariable.VariablePointers.empty());

    BVariable.VariablePointers.map(seedCandidates, function makeVarTraverse(name = name, vars_ptr = seed_vars_ptr, ht = jacobianHT, makeVar = BVariable.makeSeedVar));
    BVariable.VariablePointers.map(partialCandidates, function makeVarTraverse(name = name, vars_ptr = pDer_vars_ptr, ht = jacobianHT, makeVar = BVariable.makePDerVar));

    // Build differentiation argument structure
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),             // no explicit cref necessary, rules are set by HT
      jacobianHT      = SOME(Pointer.access(jacobianHT)), // seed and temporary cref hashtable
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcTree        = funcTree,
      diffedFunctions = AvlSetPath.new()
    );

    (diffedEquations, diffArguments) := Differentiate.differentiateEquationPointers(equations, diffArguments);

    // create equation data for jacobian
    // ToDo: split temporary and auxiliares once tearing is applied
    eqDataJac := BEquation.EQ_DATA_JAC(
      equations     = diffedEquations,
      results       = diffedEquations,
      temporary     = BEquation.EquationPointers.empty(),
      auxiliaries   = BEquation.EquationPointers.empty()
    );

    // collect var data
    unknown_vars  := listReverse(Pointer.access(pDer_vars_ptr));
    all_vars      := unknown_vars; // add other vars later on

    seed_vars     := Pointer.access(seed_vars_ptr);
    aux_vars      := seed_vars; // add other auxiliaries later on
    alias_vars    := {};
    depend_vars   := {};

    res_vars      := {};
    tmp_vars      := {}; // ToDo: add this once system has been torn

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = NBVariable.VariablePointers.fromList(all_vars),
      unknowns      = NBVariable.VariablePointers.fromList(unknown_vars),
      knowns        = knowns,
      auxiliaries   = NBVariable.VariablePointers.fromList(aux_vars),
      aliasVars     = NBVariable.VariablePointers.fromList(alias_vars),
      diffVars      = unknowns,
      dependencies  = NBVariable.VariablePointers.fromList(depend_vars),
      resultVars    = NBVariable.VariablePointers.fromList(res_vars),
      tmpVars       = NBVariable.VariablePointers.fromList(tmp_vars),
      seedVars      = NBVariable.VariablePointers.fromList(seed_vars)
    );

    if isSome(daeUnknowns) then
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(Util.getOption(daeUnknowns), unknowns, equations, strongComponents);
    else
      BEquation.EquationPointers.map(equations, function BEquation.Equation.createResidual(context = "SIM", residual_vars = residual_vars_ptr, idx = idx));
      residuals := BVariable.VariablePointers.fromList(listReverse(Pointer.access(residual_vars_ptr)));
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(unknowns, residuals, equations, strongComponents);
      // safe residuals somewhere?
    end if;

    jacobian := SOME(Jacobian.JAC(
      name              = name,
      varData           = varDataJac,
      eqData            = eqDataJac,
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));
  end jacobianSymbolic;

  function jacobianNumeric extends Module.jacobianInterface;
  protected
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;
  protected
    BVariable.VariablePointers residuals;
    Pointer<list<Pointer<Variable>>> residual_vars_ptr = Pointer.create({});
    Pointer<Integer> idx = Pointer.create(0);
  algorithm
    if isSome(daeUnknowns) then
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(Util.getOption(daeUnknowns), unknowns, equations, strongComponents);
    else
      BEquation.EquationPointers.map(equations, function BEquation.Equation.createResidual(context = "SIM", residual_vars = residual_vars_ptr, idx = idx));
      residuals := BVariable.VariablePointers.fromList(listReverse(Pointer.access(residual_vars_ptr)));
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(unknowns, residuals, equations, strongComponents);
      // safe residuals somewhere?
    end if;
    jacobian := SOME(Jacobian.JAC(
      name              = name,
      varData           = BVariable.VAR_DATA_EMPTY(),
      eqData            = BEquation.EQ_DATA_EMPTY(),
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));
  end jacobianNumeric;

  function makeVarTraverse
    input output Variable var;
    input String name;
    input Pointer<list<Pointer<Variable>>> vars_ptr;
    input Pointer<HashTableCrToCr.HashTable> ht;
    input Func makeVar;

    partial function Func
      input output ComponentRef cref;
      input String name;
      output Pointer<Variable> var_ptr;
    end Func;
  protected
    ComponentRef cref;
    Pointer<Variable> var_ptr;
  algorithm
    (cref, var_ptr) := makeVar(var.name, name);
    // add $<new>.x variable pointer to the variables
    Pointer.update(vars_ptr, var_ptr :: Pointer.access(vars_ptr));
    // add x -> $<new>.x to the hashTable for later lookup
    Pointer.update(ht, BaseHashTable.add((var.name, cref), Pointer.access(ht)));
  end makeVarTraverse;

  annotation(__OpenModelica_Interface="backend");
end NBJacobian;
