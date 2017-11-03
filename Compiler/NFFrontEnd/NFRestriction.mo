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
  record MODEL end MODEL;

  record CONNECTOR
    Boolean isExpandable;
  end CONNECTOR;

  record TYPE end TYPE;
  record ENUMERATION end ENUMERATION;
  record UNKNOWN end UNKNOWN;

  function fromSCode
    input SCode.Restriction sres;
    output Restriction res;
  algorithm
    res := match sres
      case SCode.Restriction.R_CONNECTOR()
        then CONNECTOR(sres.isExpandable);

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

annotation(__OpenModelica_Interface="frontend");
end NFRestriction;
