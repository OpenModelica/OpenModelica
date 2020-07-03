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
encapsulated package NSimVar
"file:        NSimVar.mo
 package:     NSimVar
 description: This file contains the data types and functions for variables
              in simulation code phase.
"
protected
  // OF imports
  import TplAbsyn;
  import DAE;
  import SCode;

  // NF imports
  import BackendExtension = NFBackendExtension;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Type = NFType;
  import Variable = NFVariable;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // Backend imports
  import BVariable = NBVariable;

  // Old Simcode imports
  import OldSimCodeVar = SimCodeVar;

  // Util imports
  import Error;
  import Pointer;
  import StringUtil;
  import Util;

public
  uniontype SimVar "Information about a variable in a Modelica model."
    record SIMVAR
      ComponentRef name;
      BackendExtension.VariableKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Integer index;
      Option<Expression> min;
      Option<Expression> max;
      Option<Expression> start;
      Option<Expression> nominal;
      Boolean isFixed;
      Type type_;
      Boolean isDiscrete;
      Option<ComponentRef> arrayCref "the name of the array if this variable is the first in that array";
      Alias aliasvar;
      SourceInfo info;
      Option<Causality> causality;
      Option<Integer> variable_index "valueReference";
      Option<Integer> fmi_index "index of variable in modelDescription.xml";
      list<String> numArrayElement;
      Boolean isValueChangeable;
      Boolean isProtected;
      Boolean hideResult;
      Option<array<Integer>> inputIndex;
      Option<String> matrixName "if the varibale is a jacobian var, this is the corresponding matrix";
      Option<Variability> variability "FMI-2.0 variabilty attribute";
      Option<Initial> initial_ "FMI-2.0 initial attribute";
      Option<ComponentRef> exportVar "variables will only be exported to the modelDescription.xml if this attribute is SOME(cref) and this cref is only used in ModelDescription.xml for FMI-2.0 export";
    end SIMVAR;

    function toString
      input SimVar var;
      input output String str = "";
    algorithm
      str := str + "(" + intString(var.index) + ")" + BackendExtension.VariableKind.toString(var.varKind) + " " + ComponentRef.toString(var.name);
    end toString;

    function listToString
      input list<SimVar> var_lst;
      input output String str = "";
    algorithm
      if not listEmpty(var_lst) then
        str := StringUtil.headline_4(str + " (" + intString(listLength(var_lst)) + ")");
        for var in var_lst loop
          str := str + toString(var, "  ") + "\n";
        end for;
      else
        str := "";
      end if;
    end listToString;

    function create
      input Variable var;
      output SimVar simVar;
      input output Integer uniqueIndex;
    algorithm
      simVar := match var
        local
          Variable qual;
          BackendExtension.VariableKind varKind;
          String comment, unit, displayUnit;
          Option<Expression> min;
          Option<Expression> max;
          Option<Expression> start;
          Option<Expression> nominal;
          Boolean isFixed;
          Boolean isDiscrete;
          Boolean isProtected;
          SimVar result;

        case qual as Variable.VARIABLE()
          algorithm
            comment := parseComment(qual.comment);
            (varKind, unit, displayUnit, min, max, start, nominal, isFixed, isDiscrete, isProtected) := parseAttributes(qual.backendinfo);
            result := SIMVAR(qual.name, varKind, comment, unit, displayUnit, uniqueIndex, min, max, start, nominal, isFixed, qual.ty,
                      isDiscrete, NONE(), Alias.NO_ALIAS(), qual.info, NONE(), SOME(uniqueIndex), SOME(uniqueIndex), {}, true,
                      isProtected, false, NONE(), NONE(), NONE(), NONE(), NONE());
            uniqueIndex := uniqueIndex + 1;
        then result;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable " + Variable.toString(var) + "."});
        then fail();

      end match;
    end create;

    function traverseCreate
      input output Variable var;
      input Pointer<list<SimVar>> acc;
      input Pointer<Integer> uniqueIndexPtr;
    algorithm
      Pointer.update(acc, create(var, Pointer.access(uniqueIndexPtr)) :: Pointer.access(acc));
      Pointer.update(uniqueIndexPtr, Pointer.access(uniqueIndexPtr) + 1);
    end traverseCreate;

    function convert
      input SimVar simVar;
      output OldSimCodeVar.SimVar oldSimVar;
    algorithm
      oldSimVar := OldSimCodeVar.SIMVAR(
        name                = ComponentRef.toDAE(simVar.name),
        varKind             = convertVarKind(simVar.varKind),
        comment             = simVar.comment,
        unit                = simVar.unit,
        displayUnit         = simVar.displayUnit,
        index               = simVar.index,
        minValue            = if isSome(simVar.min) then SOME(Expression.toDAE(Util.getOption(simVar.min))) else NONE(),
        maxValue            = if isSome(simVar.max) then SOME(Expression.toDAE(Util.getOption(simVar.max))) else NONE(),
        initialValue        = if isSome(simVar.start) then SOME(Expression.toDAE(Util.getOption(simVar.start))) else NONE(),
        nominalValue        = if isSome(simVar.nominal) then SOME(Expression.toDAE(Util.getOption(simVar.nominal))) else NONE(),
        isFixed             = simVar.isFixed,
        type_               = Type.toDAE(simVar.type_),
        isDiscrete          = simVar.isDiscrete,
        arrayCref           = if isSome(simVar.arrayCref) then SOME(ComponentRef.toDAE(Util.getOption(simVar.arrayCref))) else NONE(),
        aliasvar            = Alias.convert(simVar.aliasvar),
        source              = DAE.emptyElementSource, //ToDo update this!
        causality           = NONE(),  //ToDo update this!
        variable_index      = simVar.variable_index,
        fmi_index           = simVar.fmi_index,
        numArrayElement     = simVar.numArrayElement,
        isValueChangeable   = simVar.isValueChangeable,
        isProtected         = simVar.isProtected,
        hideResult          = simVar.hideResult,
        inputIndex          = simVar.inputIndex,
        matrixName          = simVar.matrixName,
        variability         = NONE(),  //ToDo update this!
        initial_            = NONE(),  //ToDo update this!
        exportVar           = if isSome(simVar.exportVar) then SOME(ComponentRef.toDAE(Util.getOption(simVar.exportVar))) else NONE());
    end convert;

    function convertList
      input list<SimVar> simVar_lst;
      output list<OldSimCodeVar.SimVar> oldSimVar_lst = {};
    algorithm
      for simVar in simVar_lst loop
        oldSimVar_lst := convert(simVar) :: oldSimVar_lst;
      end for;
      oldSimVar_lst := listReverse(oldSimVar_lst);
    end convertList;

  protected
    function parseAttributes
      input BackendExtension.BackendInfo backendInfo;
      output BackendExtension.VariableKind varKind;
      output String unit = "";
      output String displayUnit = "";
      output Option<Expression> min = NONE();
      output Option<Expression> max = NONE();
      output Option<Expression> start = NONE();
      output Option<Expression> nominal = NONE();
      output Boolean isFixed = false;
      output Boolean isDiscrete = false;
      output Boolean isProtected = false;
    algorithm
      _ := match backendInfo
        local
          BackendExtension.VariableAttributes varAttr;

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = NONE()) then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = SOME(varAttr as BackendExtension.VAR_ATTR_REAL()))
          algorithm
            if isSome(varAttr.unit) then
              unit := Expression.stringValue(Util.getOption(varAttr.unit));
            end if;
            if isSome(varAttr.displayUnit) then
              displayUnit := Expression.stringValue(Util.getOption(varAttr.displayUnit));
            end if;
            min := varAttr.min;
            max := varAttr.max;
            start := varAttr.start;
            nominal := varAttr.nominal;
            if isSome(varAttr.fixed) then
              isFixed := Expression.booleanValue(Util.getOption(varAttr.fixed));
            end if;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = SOME(varAttr as BackendExtension.VAR_ATTR_INT()))
          algorithm
            min := varAttr.min;
            max := varAttr.max;
            start := varAttr.start;
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = SOME(varAttr as BackendExtension.VAR_ATTR_BOOL()))
          algorithm
            start := varAttr.start;
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = SOME(varAttr as BackendExtension.VAR_ATTR_CLOCK()))
          algorithm
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = SOME(varAttr as BackendExtension.VAR_ATTR_STRING()))
          algorithm
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        case BackendExtension.BACKEND_INFO(varKind = varKind, attributes = SOME(varAttr as BackendExtension.VAR_ATTR_ENUMERATION()))
          algorithm
            isDiscrete := true;
            if isSome(varAttr.isProtected) then
              SOME(isProtected) := varAttr.isProtected;
            end if;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the BackendInfo could not be parsed."});
        then fail();
      end match;
    end parseAttributes;

    function parseComment
      input Option<SCode.Comment> absynComment;
      output String commentStr;
    algorithm
      commentStr := match (absynComment)
        case (SOME(SCode.COMMENT(_, SOME(commentStr)))) then commentStr;
        else "";
      end match;
    end parseComment;

    function convertVarKind
      "Usually this function would belong to NFBackendExtension, but we want to
      avoid Frontend -> Backend dependency."
      input BackendExtension.VariableKind varKind;
      output OldBackendDAE.VarKind oldVarKind;
    algorithm
      oldVarKind := match varKind
        local
          BackendExtension.VariableKind qual;
          Variable var;
          Option<DAE.ComponentRef> oldCrefOpt;
          DAE.ComponentRef oldCref;

        case BackendExtension.ALGEBRAIC()               then OldBackendDAE.VARIABLE();
        case qual as BackendExtension.STATE()
          algorithm
            if isSome(qual.derivative) then
              var := Pointer.access(Util.getOption(qual.derivative));
              oldCrefOpt := SOME(ComponentRef.toDAE(var.name));
            else
              oldCrefOpt := NONE();
            end if;
        then OldBackendDAE.STATE(qual.index, oldCrefOpt, qual.natural);
        case BackendExtension.STATE_DER()               then OldBackendDAE.STATE_DER();
        case BackendExtension.DUMMY_DER()               then OldBackendDAE.DUMMY_DER();
        case BackendExtension.DUMMY_STATE()             then OldBackendDAE.DUMMY_STATE();
        case BackendExtension.DISCRETE()                then OldBackendDAE.DISCRETE();
        case qual as BackendExtension.DISCRETE_STATE()
          algorithm
            var := Pointer.access(qual.previous);
            oldCref := ComponentRef.toDAE(var.name);
        then OldBackendDAE.CLOCKED_STATE(oldCref, qual.fixed);
        case BackendExtension.PREVIOUS()                then OldBackendDAE.DISCRETE();
        case BackendExtension.PARAMETER()               then OldBackendDAE.PARAM();
        case BackendExtension.CONSTANT()                then OldBackendDAE.CONST();
        //ToDo: check this! is this correct? need typechecking?
        case BackendExtension.START()                   then OldBackendDAE.VARIABLE();
        case qual as BackendExtension.EXTOBJ()          then OldBackendDAE.EXTOBJ(qual.fullClassName);
        case BackendExtension.JAC_VAR()                 then OldBackendDAE.JAC_VAR();
        case BackendExtension.JAC_DIFF_VAR()            then OldBackendDAE.JAC_DIFF_VAR();
        case BackendExtension.SEED_VAR()                then OldBackendDAE.SEED_VAR();
        case BackendExtension.OPT_CONSTR()              then OldBackendDAE.OPT_CONSTR();
        case BackendExtension.OPT_FCONSTR()             then OldBackendDAE.OPT_FCONSTR();
        case BackendExtension.OPT_INPUT_WITH_DER()      then OldBackendDAE.OPT_INPUT_WITH_DER();
        case BackendExtension.OPT_INPUT_DER()           then OldBackendDAE.OPT_INPUT_DER();
        case BackendExtension.OPT_TGRID()               then OldBackendDAE.OPT_TGRID();
        case qual as BackendExtension.OPT_LOOP_INPUT()  then OldBackendDAE.OPT_LOOP_INPUT(ComponentRef.toDAE(qual.replaceCref));
        // ToDo maybe deprecated:
        case BackendExtension.ALG_STATE()               then OldBackendDAE.ALG_STATE();
        case BackendExtension.ALG_STATE_OLD()           then OldBackendDAE.ALG_STATE_OLD();
        case BackendExtension.DAE_RESIDUAL_VAR()        then OldBackendDAE.DAE_RESIDUAL_VAR();
        case BackendExtension.DAE_AUX_VAR()             then OldBackendDAE.DAE_AUX_VAR();
        case BackendExtension.LOOP_ITERATION()          then OldBackendDAE.LOOP_ITERATION();
        case BackendExtension.LOOP_SOLVED()             then OldBackendDAE.LOOP_SOLVED();
        case BackendExtension.FRONTEND_DUMMY()
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong VariableKind FRONTEND_DUMMY(). This should not exist after frontend."});
        then fail();
        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unhandled VariableKind " + BackendExtension.VariableKind.toString(varKind) + "."});
        then fail();
      end match;
    end convertVarKind;
  end SimVar;

  uniontype Alias
    record NO_ALIAS end NO_ALIAS;
    record ALIAS
      "General alias expression with a coefficent.
      var := coefficent * alias"
      ComponentRef alias    "The name of the alias variable.";
      Real coefficient      " = 1 for regular alias.";
    end ALIAS;

    function convert
      input Alias alias;
      output OldSimCodeVar.AliasVariable oldAlias;
    algorithm
      oldAlias := match alias
        local
          Alias qual;
        case NO_ALIAS() then OldSimCodeVar.NOALIAS();
        case qual as ALIAS() guard(realEq(qual.coefficient, 1.0)) then OldSimCodeVar.ALIAS(ComponentRef.toDAE(qual.alias));
        case qual as ALIAS() guard(realEq(qual.coefficient, -1.0)) then OldSimCodeVar.NEGATEDALIAS(ComponentRef.toDAE(qual.alias));
        case qual as ALIAS()
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the old SimCode can only parse a coefficent for ALIAS() of exactly 1 or -1. Got coefficient: " + realString(qual.coefficient)});
        then fail();
        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown Alias type."});
        then fail();
      end match;
    end convert;
  end Alias;

  // kabdelhak: i don't like "CALCULATED_PARAMETER", is there a better way to describe it?
  type Causality = enumeration(NONE, OUTPUT, INPUT, LOCAL, PARAMETER, CALCULATED_PARAMETER);
  // kabdelhak: where is the difference between approx and calculated?
  type Initial = enumeration(NONE, EXACT, APPROX, CALCULATED);
  // kabdelhak: i don't like "TUNABLE" -> just "VARIABLE"?
  type Variability = enumeration(CONSTANT, FIXED, TUNABLE, DISCRETE, CONTINUOUS);

  uniontype SimVars "Container for metadata about variables in a Modelica model."
    record SIMVARS
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> discreteAlgVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> stringAliasVars;
      list<SimVar> extObjVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
      list<SimVar> jacobianVars;
      list<SimVar> seedVars;
      list<SimVar> realOptimizeConstraintsVars;
      list<SimVar> realOptimizeFinalConstraintsVars;
      list<SimVar> sensitivityVars "variable used to calculate sensitivities for parameters nSensitivitityParameters + nRealParam*nStates";
      list<SimVar> dataReconSetcVars;
      list<SimVar> dataReconinputVars;
    end SIMVARS;

    function toString
      input SimVars vars;
      input output String str = "";
    algorithm
      str := StringUtil.headline_2("SimVars " + str);
      str := str + SimVar.listToString(vars.stateVars, "States") + "\n";
      str := str + SimVar.listToString(vars.derivativeVars, "Derivatives") + "\n";
      str := str + SimVar.listToString(vars.algVars, "Algebraic Variables") + "\n";
      str := str + SimVar.listToString(vars.intParamVars, "Integer Parameters") + "\n";
      // ToDo: all the other stuff
    end toString;

    function create
      input BVariable.VarData varData;
      output SimVars simVars;
    protected
      Integer uniqueIndex = 0;
      list<SimVar> stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, stringAlgVars;
      list<SimVar> inputVars = {};
      list<SimVar> outputVars = {};
      list<SimVar> aliasVars, intAliasVars, boolAliasVars, stringAliasVars;
      list<SimVar> paramVars, intParamVars, boolParamVars, stringParamVars;
      list<SimVar> constVars, intConstVars, boolConstVars, stringConstVars;
      list<SimVar> extObjVars = {};
      list<SimVar> jacobianVars = {};
      list<SimVar> seedVars = {};
      list<SimVar> realOptimizeConstraintsVars = {};
      list<SimVar> realOptimizeFinalConstraintsVars = {};
      list<SimVar> sensitivityVars = {};
      list<SimVar> dataReconSetcVars = {};
      list<SimVar> dataReconinputVars = {};
    algorithm
      _ := match varData
        local
          BVariable.VarData qual;

        case qual as BVariable.VAR_DATA_SIM()
          algorithm
            ({stateVars}, uniqueIndex) := createSimVarLists(qual.states, uniqueIndex);
            ({derivativeVars}, uniqueIndex) := createSimVarLists(qual.derivatives, uniqueIndex);
            ({algVars}, uniqueIndex) := createSimVarLists(qual.algebraics, uniqueIndex);
            ({discreteAlgVars, intAlgVars, boolAlgVars, stringAlgVars}, uniqueIndex) := createSimVarLists(qual.discretes, uniqueIndex, SplitType.TYPE);
            ({aliasVars, intAliasVars, boolAliasVars, stringAliasVars}, uniqueIndex) := createSimVarLists(qual.aliasVars, uniqueIndex, SplitType.TYPE);
            ({paramVars, intParamVars, boolParamVars, stringParamVars}, uniqueIndex) := createSimVarLists(qual.parameters, uniqueIndex, SplitType.TYPE);
            ({constVars, intConstVars, boolConstVars, stringConstVars}, uniqueIndex) := createSimVarLists(qual.constants, uniqueIndex, SplitType.TYPE);
        then ();

        case qual as BVariable.VAR_DATA_JAC() then ();
        case qual as BVariable.VAR_DATA_HES() then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;

      simVars := SIMVARS(stateVars, derivativeVars, algVars, discreteAlgVars,
        intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars,
        boolAliasVars, paramVars, intParamVars, boolParamVars, stringAlgVars,
        stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars,
        boolConstVars, stringConstVars, jacobianVars, seedVars,
        realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars,
        sensitivityVars, dataReconSetcVars, dataReconinputVars);
    end create;

    function convert
      input SimVars simVars;
      output OldSimCodeVar.SimVars oldSimVars;
    algorithm
      oldSimVars := OldSimCodeVar.SIMVARS(
        stateVars                         = SimVar.convertList(simVars.stateVars),
        derivativeVars                    = SimVar.convertList(simVars.derivativeVars),
        algVars                           = SimVar.convertList(simVars.algVars),
        discreteAlgVars                   = SimVar.convertList(simVars.discreteAlgVars),
        intAlgVars                        = SimVar.convertList(simVars.intAlgVars),
        boolAlgVars                       = SimVar.convertList(simVars.boolAlgVars),
        inputVars                         = SimVar.convertList(simVars.inputVars),
        outputVars                        = SimVar.convertList(simVars.outputVars),
        aliasVars                         = SimVar.convertList(simVars.aliasVars),
        intAliasVars                      = SimVar.convertList(simVars.intAliasVars),
        boolAliasVars                     = SimVar.convertList(simVars.boolAliasVars),
        paramVars                         = SimVar.convertList(simVars.paramVars),
        intParamVars                      = SimVar.convertList(simVars.intParamVars),
        boolParamVars                     = SimVar.convertList(simVars.boolParamVars),
        stringAlgVars                     = SimVar.convertList(simVars.stringAlgVars),
        stringParamVars                   = SimVar.convertList(simVars.stringParamVars),
        stringAliasVars                   = SimVar.convertList(simVars.stringAliasVars),
        extObjVars                        = SimVar.convertList(simVars.extObjVars),
        constVars                         = SimVar.convertList(simVars.constVars),
        intConstVars                      = SimVar.convertList(simVars.intConstVars),
        boolConstVars                     = SimVar.convertList(simVars.boolConstVars),
        stringConstVars                   = SimVar.convertList(simVars.stringConstVars),
        jacobianVars                      = SimVar.convertList(simVars.jacobianVars),
        seedVars                          = SimVar.convertList(simVars.seedVars),
        realOptimizeConstraintsVars       = SimVar.convertList(simVars.realOptimizeConstraintsVars),
        realOptimizeFinalConstraintsVars  = SimVar.convertList(simVars.realOptimizeFinalConstraintsVars),
        sensitivityVars                   = SimVar.convertList(simVars.sensitivityVars),
        dataReconSetcVars                 = SimVar.convertList(simVars.dataReconSetcVars),
        dataReconinputVars                = SimVar.convertList(simVars.dataReconinputVars));
    end convert;

  protected
    type SplitType = enumeration(NONE, TYPE);

    function createSimVarLists
      "creates a list of simvar lists. SplitType.NONE always returns a list with only
      one list as its element and SplitType.TYPE returns a list with four lists."
      input BVariable.VariablePointers vars;
      output list<list<SimVar>> simVars = {};
      input output Integer uniqueIndex;
      input SplitType splitType = SplitType.NONE;
    protected
      Pointer<list<SimVar>> acc = Pointer.create({});
      Pointer<list<SimVar>> real_lst = Pointer.create({});
      Pointer<list<SimVar>> int_lst = Pointer.create({});
      Pointer<list<SimVar>> bool_lst = Pointer.create({});
      Pointer<list<SimVar>> string_lst = Pointer.create({});
      Pointer<Integer> uniqueIndexPtr = Pointer.create(uniqueIndex);
    algorithm
      if splitType == SplitType.NONE then
        // Do not split and return everything as one single list
        BVariable.VariablePointers.map(vars, function SimVar.traverseCreate(acc = acc, uniqueIndexPtr = uniqueIndexPtr));
        simVars := {Pointer.access(acc)};
        uniqueIndex := Pointer.access(uniqueIndexPtr);
      elseif splitType == SplitType.TYPE then
        // Split the variables by basic type (real, integer, boolean, string)
        // and return a list for each type
        BVariable.VariablePointers.map(vars, function splitByType(real_lst = real_lst, int_lst = int_lst, bool_lst = bool_lst, string_lst = string_lst, uniqueIndexPtr = uniqueIndexPtr));
        simVars := {Pointer.access(real_lst), Pointer.access(int_lst), Pointer.access(bool_lst), Pointer.access(string_lst)};
        uniqueIndex := Pointer.access(uniqueIndexPtr);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of invalid splitType."});
      end if;
    end createSimVarLists;

    function splitByType
      "Traverser function for splitting process. Target for SplitType.TYPE"
      input output Variable var;
      input Pointer<list<SimVar>> real_lst;
      input Pointer<list<SimVar>> int_lst;
      input Pointer<list<SimVar>> bool_lst;
      input Pointer<list<SimVar>> string_lst;
      input Pointer<Integer> uniqueIndexPtr;
    algorithm
      _ := match var.ty
        case Type.REAL()
          algorithm
            Pointer.update(real_lst, SimVar.create(var, Pointer.access(uniqueIndexPtr)) :: Pointer.access(real_lst));
            Pointer.update(uniqueIndexPtr, Pointer.access(uniqueIndexPtr) + 1);
        then ();

        case Type.INTEGER()
          algorithm
            Pointer.update(int_lst, SimVar.create(var, Pointer.access(uniqueIndexPtr)) :: Pointer.access(int_lst));
            Pointer.update(uniqueIndexPtr, Pointer.access(uniqueIndexPtr) + 1);
        then ();

        case Type.BOOLEAN()
          algorithm
            Pointer.update(bool_lst, SimVar.create(var, Pointer.access(uniqueIndexPtr)) :: Pointer.access(bool_lst));
            Pointer.update(uniqueIndexPtr, Pointer.access(uniqueIndexPtr) + 1);
        then ();

        case Type.STRING()
          algorithm
            Pointer.update(string_lst, SimVar.create(var, Pointer.access(uniqueIndexPtr)) :: Pointer.access(string_lst));
            Pointer.update(uniqueIndexPtr, Pointer.access(uniqueIndexPtr) + 1);
        then ();

        else ();

      end match;
    end splitByType;

  end SimVars;

  constant SimVars emptySimVars = SIMVARS({}, {}, {}, {}, {}, {}, {}, {},
    {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {});


  annotation(__OpenModelica_Interface="backend");
end NSimVar;
