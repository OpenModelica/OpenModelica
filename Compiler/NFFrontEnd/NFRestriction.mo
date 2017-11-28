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
  record RECORD end RECORD;
  record TYPE end TYPE;
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
      case SCode.Restriction.R_RECORD() then RECORD();
      case SCode.Restriction.R_TYPE() then TYPE();
      else MODEL();
    end match;
  end fromSCode;

  function isConnector
    input Restriction res;
    output Boolean isConnector;
  algorithm
    isConnector := match res
      case CONNECTOR() then true;
      else false;
    end match;
  end isConnector;

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

annotation(__OpenModelica_Interface="frontend");
end NFRestriction;
