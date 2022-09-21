/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated uniontype NFRestriction
  import ClassInf;
  import InstContext = NFInstContext;
  import NFInstNode.InstNode;
  import SCode;

protected
  import Restriction = NFRestriction;
  import SCodeUtil;

public
  record BLOCK end BLOCK;
  record CLASS end CLASS;
  record CLOCK end CLOCK;

  record CONNECTOR
    Boolean isExpandable;
  end CONNECTOR;

  record ENUMERATION end ENUMERATION;
  record EXTERNAL_OBJECT end EXTERNAL_OBJECT;
  record FUNCTION end FUNCTION;
  record MODEL end MODEL;
  record PACKAGE end PACKAGE;
  record OPERATOR end OPERATOR;

  record RECORD
    Boolean isOperator;
    Boolean usedExternally;
  end RECORD;

  record RECORD_CONSTRUCTOR end RECORD_CONSTRUCTOR;
  record TYPE end TYPE;
  record UNKNOWN end UNKNOWN;

  function fromSCode
    input SCode.Restriction sres;
    output Restriction res;
  algorithm
    res := match sres
      case SCode.Restriction.R_BLOCK() then BLOCK();
      case SCode.Restriction.R_CLASS() then CLASS();
      case SCode.Restriction.R_PREDEFINED_CLOCK() then CLOCK();
      case SCode.Restriction.R_CONNECTOR() then CONNECTOR(sres.isExpandable);
      case SCode.Restriction.R_ENUMERATION() then ENUMERATION();
      case SCode.Restriction.R_FUNCTION() then FUNCTION();
      case SCode.Restriction.R_MODEL() then MODEL();
      case SCode.Restriction.R_OPERATOR() then OPERATOR();
      case SCode.Restriction.R_PACKAGE() then PACKAGE();
      case SCode.Restriction.R_RECORD() then RECORD(sres.isOperator, false);
      case SCode.Restriction.R_TYPE() then TYPE();
      else MODEL();
    end match;
  end fromSCode;

  function toDAE
    input Restriction res;
    input Absyn.Path path;
    output ClassInf.State state;
  algorithm
    state := match res
      case BLOCK() then ClassInf.State.BLOCK(path);
      case CLOCK() then ClassInf.State.TYPE_CLOCK(path);
      case CONNECTOR() then ClassInf.State.CONNECTOR(path, res.isExpandable);
      case ENUMERATION() then ClassInf.State.ENUMERATION(path);
      case EXTERNAL_OBJECT() then ClassInf.State.EXTERNAL_OBJ(path);
      case FUNCTION() then ClassInf.State.FUNCTION(path, false);
      case MODEL() then ClassInf.State.MODEL(path);
      case OPERATOR() then ClassInf.State.FUNCTION(path, false);
      case PACKAGE() then ClassInf.State.PACKAGE(path);
      case RECORD() then ClassInf.State.RECORD(path);
      case RECORD_CONSTRUCTOR() then ClassInf.State.RECORD(path);
      case TYPE() then ClassInf.State.TYPE(path);
      else ClassInf.State.UNKNOWN(path);
    end match;
  end toDAE;

  function isConnector
    input Restriction res;
    output Boolean isConnector;
  algorithm
    isConnector := match res
      case CONNECTOR() then true;
      else false;
    end match;
  end isConnector;

  function isExpandableConnector
    input Restriction res;
    output Boolean isConnector;
  algorithm
    isConnector := match res
      case CONNECTOR() then res.isExpandable;
      else false;
    end match;
  end isExpandableConnector;

  function isNonexpandableConnector
    input Restriction res;
    output Boolean isNonexpandable;
  algorithm
    isNonexpandable := match res
      case CONNECTOR() then not res.isExpandable;
      else false;
    end match;
  end isNonexpandableConnector;

  function isExternalObject
    input Restriction res;
    output Boolean isExternalObject;
  algorithm
    isExternalObject := match res
      case EXTERNAL_OBJECT() then true;
      else false;
    end match;
  end isExternalObject;

  function isFunction
    input Restriction res;
    output Boolean isFunction;
  algorithm
    isFunction := match res
      case FUNCTION() then true;
      else false;
    end match;
  end isFunction;

  function isRecordConstructor
    input Restriction res;
    output Boolean isConstructor;
  algorithm
    isConstructor := match res
      case RECORD_CONSTRUCTOR() then true;
      else false;
    end match;
  end isRecordConstructor;

  function isRecord
    input Restriction res;
    output Boolean isRecord;
  algorithm
    isRecord := match res
      case RECORD() then true;
      else false;
    end match;
  end isRecord;

  function isExternalRecord
    input Restriction res;
    output Boolean isExtRecord;
  algorithm
    isExtRecord := match res
      case RECORD() then res.usedExternally;
      else false;
    end match;
  end isExternalRecord;

  function setExternalRecord
    input output Restriction res;
  algorithm
    () := match res
      case RECORD(usedExternally = false)
        algorithm
          res.usedExternally := true;
        then
          ();

      else ();
    end match;
  end setExternalRecord;

  function isOperatorRecord
    input Restriction res;
    output Boolean isOpRecord;
  algorithm
    isOpRecord := match res
      case RECORD() then res.isOperator;
      else false;
    end match;
  end isOperatorRecord;

  function isOperator
    input Restriction res;
    output Boolean isOperator;
  algorithm
    isOperator := match res
      case OPERATOR() then true;
      else false;
    end match;
  end isOperator;

  function isType
    input Restriction res;
    output Boolean isType;
  algorithm
    isType := match res
      case TYPE() then true;
      else false;
    end match;
  end isType;

  function isClock
    input Restriction res;
    output Boolean isClock;
  algorithm
    isClock := match res
      case CLOCK() then true;
      else false;
    end match;
  end isClock;

  function isModel
    input Restriction res;
    output Boolean isModel;
  algorithm
    isModel := match res
      case MODEL() then true;
      else false;
    end match;
  end isModel;

  function toString
    input Restriction res;
    output String str;
  algorithm
    str := match res
      case BLOCK() then "block";
      case CLASS() then "class";
      case CLOCK() then "clock";
      case CONNECTOR()
        then if res.isExpandable then "expandable connector" else "connector";
      case ENUMERATION() then "enumeration";
      case EXTERNAL_OBJECT() then "ExternalObject";
      case FUNCTION() then "function";
      case MODEL() then "model";
      case OPERATOR() then "operator";
      case PACKAGE() then "package";
      case RECORD() then "record";
      case RECORD_CONSTRUCTOR() then "record";
      case TYPE() then "type";
      else "unknown";
    end match;
  end toString;

  function assertNoEquations
    input list<SCode.Equation> equations;
    input list<SCode.Equation> initialEquations;
    input Restriction res;
    input Boolean onlyDeprecated = false;
  protected
    SCode.Equation eq;
  algorithm
    if listEmpty(equations) and listEmpty(initialEquations) then
      return;
    end if;

    eq := listHead(if listEmpty(equations) then initialEquations else equations);

    if onlyDeprecated then
      Error.addSourceMessage(Error.DEPRECATED_TRANSITION_FAILURE,
        {"Equation sections", Restriction.toString(res)}, SCodeUtil.getEquationInfo(eq));
    else
      Error.addSourceMessage(Error.EQUATION_TRANSITION_FAILURE,
        {Restriction.toString(res)}, SCodeUtil.getEquationInfo(eq));
      fail();
    end if;
  end assertNoEquations;

  function assertNoAlgorithms
    input list<SCode.AlgorithmSection> algorithms;
    input list<SCode.AlgorithmSection> initialAlgorithms;
    input Restriction res;
    input Boolean onlyDeprecated = false;
  protected
    Option<SCode.AlgorithmSection> alg_opt = NONE();
    SCode.AlgorithmSection alg;
    SourceInfo info;
  algorithm
    alg_opt := List.findOption(algorithms, SCodeUtil.isNonEmptyAlgorithm);

    if isNone(alg_opt) then
      alg_opt := List.findOption(initialAlgorithms, SCodeUtil.isNonEmptyAlgorithm);
    end if;

    if isSome(alg_opt) then
      SOME(alg) := alg_opt;
      info := SCodeUtil.getStatementInfo(listHead(alg.statements));

      if onlyDeprecated then
        Error.addSourceMessage(Error.DEPRECATED_TRANSITION_FAILURE,
          {"Algorithm sections", Restriction.toString(res)}, info);
        return;
      else
        Error.addSourceMessage(Error.ALGORITHM_TRANSITION_FAILURE,
          {Restriction.toString(res)}, info);
        fail();
      end if;
    end if;
  end assertNoAlgorithms;

  function assertNoInitialAlgorithms
    input list<SCode.AlgorithmSection> algs;
    input Restriction res;
  algorithm
    for alg in algs loop
      if not listEmpty(alg.statements) then
        Error.addSourceMessage(Error.INITIAL_ALGORITHM_TRANSITION_FAILURE,
          {Restriction.toString(res)}, SCodeUtil.getStatementInfo(listHead(alg.statements)));
        fail();
      end if;
    end for;
  end assertNoInitialAlgorithms;

  function assertNoProtected
    input list<SCode.Element> elements;
    input Restriction res;
  algorithm
    for e in elements loop
      if SCodeUtil.isElementProtected(e) then
        Error.addSourceMessage(Error.PROTECTED_TRANSITION_FAILURE,
          {Restriction.toString(res)}, SCodeUtil.elementInfo(e));
        fail();
      end if;
    end for;
  end assertNoProtected;

  function assertNoComponents
    input list<SCode.Element> elements;
    input Restriction res;
  algorithm
    for e in elements loop
      if SCodeUtil.isComponent(e) then
        Error.addSourceMessage(Error.DEPRECATED_TRANSITION_FAILURE,
          {"Components", Restriction.toString(res)}, SCodeUtil.elementInfo(e));
      end if;
    end for;
  end assertNoComponents;

  function assertOnlyConstantComponents
    input list<SCode.Element> elements;
    input InstNode clsNode;
  algorithm
    for e in elements loop
      () := match e
        case SCode.Element.COMPONENT()
          guard not SCodeUtil.isConstant(SCodeUtil.attrVariability(e.attributes))
          algorithm
            Error.addSourceMessage(Error.PACKAGE_VARIABLE_NOT_CONSTANT,
              {e.name, InstNode.name(clsNode)}, e.info);
          then
            fail();

        else ();
      end match;
    end for;
  end assertOnlyConstantComponents;

  function assertOnlyFunctions
    input list<SCode.Element> elements;
    input Restriction res;
  algorithm
    for e in elements loop
      if not SCodeUtil.isFunction(e) then

      end if;
    end for;
  end assertOnlyFunctions;

  function checkClass
    input InstNode node;
    input Restriction restriction;
    input InstContext.Type context;
  protected
    SCode.ClassDef cdef;
  algorithm
    if InstContext.inRelaxed(context) then
      return;
    end if;

    cdef := SCodeUtil.getClassBody(InstNode.definition(node));

    () := match cdef
      case SCode.ClassDef.PARTS()
        algorithm
          () := match restriction
            case Restriction.CLASS()
              algorithm
                // Components, equations, and algorithms are deprecated in classes.
                assertNoComponents(cdef.elementLst, restriction);
                assertNoEquations(cdef.normalEquationLst, cdef.initialEquationLst,
                  restriction, onlyDeprecated = true);
                assertNoAlgorithms(cdef.normalAlgorithmLst, cdef.initialAlgorithmLst,
                  restriction, onlyDeprecated = true);
              then
                ();

            case Restriction.RECORD()
              algorithm
                // Records and operator records may only contain public sections.
                assertNoProtected(cdef.elementLst, restriction);
                assertNoEquations(cdef.normalEquationLst, cdef.initialEquationLst, restriction);
                assertNoAlgorithms(cdef.normalAlgorithmLst, cdef.initialAlgorithmLst, restriction);
              then
                ();

            case Restriction.TYPE()
              algorithm
                // Types may only contain public sections.
                assertNoProtected(cdef.elementLst, restriction);
                assertNoEquations(cdef.normalEquationLst, cdef.initialEquationLst, restriction);
                assertNoAlgorithms(cdef.normalAlgorithmLst, cdef.initialAlgorithmLst, restriction);
              then
                ();

            case Restriction.BLOCK()
              algorithm
                // TODO: Components in any connector components in a block must be input/output.
              then
                ();

            case Restriction.FUNCTION()
              algorithm
                // Functions may not contain equations or initial algorithms.
                assertNoEquations(cdef.normalEquationLst, cdef.initialEquationLst, restriction);
                assertNoInitialAlgorithms(cdef.initialAlgorithmLst, restriction);
                // TODO: May only contain components of class type, record, operator record and function.
              then
                ();

            case Restriction.CONNECTOR()
              algorithm
                // Connnectors may only contain public sections.
                assertNoProtected(cdef.elementLst, restriction);
                assertNoEquations(cdef.normalEquationLst, cdef.initialEquationLst, restriction);
                assertNoAlgorithms(cdef.normalAlgorithmLst, cdef.initialAlgorithmLst, restriction);
                // TODO: Components may only be connectors, records, or types.
              then
                ();

            case Restriction.PACKAGE()
              algorithm
                // All components in a package must be constants.
                assertOnlyConstantComponents(cdef.elementLst, node);
                // Packages may not contain equations or algorithms.
                assertNoEquations(cdef.normalEquationLst, cdef.initialEquationLst, restriction);
                assertNoAlgorithms(cdef.normalAlgorithmLst, cdef.initialAlgorithmLst, restriction);
              then
                ();

            case Restriction.OPERATOR()
              algorithm
                // TODO: Only function declarations are allowed
                // Operators may not contain equations or algorithms.
                assertNoEquations(cdef.normalEquationLst, cdef.initialEquationLst, restriction);
                assertNoAlgorithms(cdef.normalAlgorithmLst, cdef.initialAlgorithmLst, restriction);
              then
                ();

            else ();
          end match;
      then
        ();

      else ();
    end match;
  end checkClass;

annotation(__OpenModelica_Interface="frontend");
end NFRestriction;
