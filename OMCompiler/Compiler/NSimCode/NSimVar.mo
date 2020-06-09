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
  import DAE;
  import SCode;

  // NF imports
  import BackendExtension = NFBackendExtension;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import BVariable = NBVariable;

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
      Boolean exportVar "variables will only be exported to the modelDescription.xml if this attribute is true";
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
                      isProtected, false, NONE(), NONE(), NONE(), NONE(), true);
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
  end SimVar;

  uniontype Alias
    record NO_ALIAS end NO_ALIAS;
    record ALIAS
      "General alias expression with a coefficent.
      var := coefficent * alias"
      ComponentRef alias    "The name of the alias variable.";
      Real coefficient      " = 1 for regular alias.";
    end ALIAS;
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
      str := StringUtil.headline_2(str);
      str := str + SimVar.listToString(vars.stateVars, "States");
      str := str + SimVar.listToString(vars.derivativeVars, "Derivatives");
      str := str + SimVar.listToString(vars.algVars, "Algebraic Variables");
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
            ({stateVars}, uniqueIndex) := createSimVarList(qual.states, uniqueIndex);
            ({derivativeVars}, uniqueIndex) := createSimVarList(qual.derivatives, uniqueIndex);
            ({algVars}, uniqueIndex) := createSimVarList(qual.algebraics, uniqueIndex);
            ({discreteAlgVars, intAlgVars, boolAlgVars, stringAlgVars}, uniqueIndex) := createSimVarList(qual.discretes, uniqueIndex, SplitType.TYPE);
            ({aliasVars, intAliasVars, boolAliasVars, stringAliasVars}, uniqueIndex) := createSimVarList(qual.aliasVars, uniqueIndex, SplitType.TYPE);
            ({paramVars, intParamVars, boolParamVars, stringParamVars}, uniqueIndex) := createSimVarList(qual.parameters, uniqueIndex, SplitType.TYPE);
            ({constVars, intConstVars, boolConstVars, stringConstVars}, uniqueIndex) := createSimVarList(qual.constants, uniqueIndex, SplitType.TYPE);
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

  protected
    type SplitType = enumeration(NONE, TYPE);

    function createSimVarList
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
    end createSimVarList;

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
