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
  import NFInstNode.InstNode;
  import ClassInf;

protected
  import Restriction = NFRestriction;

public
  record CLASS end CLASS;

  record CONNECTOR
    Boolean isExpandable;
  end CONNECTOR;

  record ENUMERATION end ENUMERATION;
  record EXTERNAL_OBJECT end EXTERNAL_OBJECT;
  record FUNCTION end FUNCTION;
  record MODEL end MODEL;
  record OPERATOR end OPERATOR;

  record RECORD
    Boolean isOperator;
  end RECORD;

  record RECORD_CONSTRUCTOR end RECORD_CONSTRUCTOR;
  record TYPE end TYPE;
  record CLOCK end CLOCK;
  record UNKNOWN end UNKNOWN;

  function fromSCode
    input SCode.Restriction sres;
    output Restriction res;
  algorithm
    res := match sres
      case SCode.Restriction.R_CLASS() then CLASS();
      case SCode.Restriction.R_CONNECTOR() then CONNECTOR(sres.isExpandable);
      case SCode.Restriction.R_ENUMERATION() then ENUMERATION();
      case SCode.Restriction.R_FUNCTION() then FUNCTION();
      case SCode.Restriction.R_MODEL() then MODEL();
      case SCode.Restriction.R_OPERATOR() then OPERATOR();
      case SCode.Restriction.R_RECORD() then RECORD(sres.isOperator);
      case SCode.Restriction.R_TYPE() then TYPE();
      case SCode.Restriction.R_PREDEFINED_CLOCK() then CLOCK();
      else MODEL();
    end match;
  end fromSCode;

  function toDAE
    input Restriction res;
    input Absyn.Path path;
    output ClassInf.State state;
  algorithm
    state := match res
      case CLASS() then ClassInf.State.UNKNOWN(path);
      case CONNECTOR() then ClassInf.State.CONNECTOR(path, res.isExpandable);
      case ENUMERATION() then ClassInf.State.ENUMERATION(path);
      case EXTERNAL_OBJECT() then ClassInf.State.EXTERNAL_OBJ(path);
      case FUNCTION() then ClassInf.State.FUNCTION(path, false);
      case MODEL() then ClassInf.State.MODEL(path);
      case OPERATOR() then ClassInf.State.FUNCTION(path, false);
      case RECORD() then ClassInf.State.RECORD(path);
      case TYPE() then ClassInf.State.TYPE(path);
      case CLOCK() then ClassInf.State.TYPE_CLOCK(path);
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

  function isRecord
    input Restriction res;
    output Boolean isRecord;
  algorithm
    isRecord := match res
      case RECORD() then true;
      else false;
    end match;
  end isRecord;

  function isOperatorRecord
    input Restriction res;
    output Boolean isOpRecord;
  algorithm
    isOpRecord := match res
      case RECORD() then res.isOperator;
      else false;
    end match;
  end isOperatorRecord;

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

  function toString
    input Restriction res;
    output String str;
  algorithm
    str := match res
      case CLASS() then "class";
      case CONNECTOR()
        then if res.isExpandable then "expandable connector" else "connector";
      case ENUMERATION() then "enumeration";
      case EXTERNAL_OBJECT() then "ExternalObject";
      case FUNCTION() then "function";
      case MODEL() then "model";
      case OPERATOR() then "operator";
      case RECORD() then "record";
      case RECORD_CONSTRUCTOR() then "record";
      case TYPE() then "type";
      case CLOCK() then "clock";
      else "unknown";
    end match;
  end toString;

annotation(__OpenModelica_Interface="frontend");
end NFRestriction;
