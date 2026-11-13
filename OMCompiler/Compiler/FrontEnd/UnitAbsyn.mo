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

encapsulated package UnitAbsyn

public import MMath;
public import HashTable;

public uniontype UnitCheckResult
  record CONSISTENT end CONSISTENT;  // May be complete or incomplete
  record INCONSISTENT
     SpecUnit u1;  //Left unit
     SpecUnit u2;  //Right unit
  end INCONSISTENT;
end UnitCheckResult;

public
uniontype SpecUnit
  record SPECUNIT " "
    list<tuple<MMath.Rational,TypeParameter>> typeParameters "A type parameter also has an exponent.";
    list<MMath.Rational> units "first seven elements are the SI base units";
  end SPECUNIT;
end SpecUnit;

public
uniontype TypeParameter
  record TYPEPARAMETER
    String name "a type parameter name has the form identifier followed by a apostrophe, e.g. p' ";
    Integer indx "indx in Store";
  end TYPEPARAMETER;
end TypeParameter;

public
uniontype Unit "A unit is either specified (including type parameters) or unspecified"

  record SPECIFIED " A specified unit"
    SpecUnit specified;
  end  SPECIFIED;

 record UNSPECIFIED "Unpspecified unit means that the unit is unknown and should be inferred" end UNSPECIFIED;
end Unit;

public
uniontype Store
  record STORE
    array<Option<Unit>> storeVector;
    Integer numElts "Number of elements stored in vector" ;
  end STORE;
end Store;

uniontype InstStore "A store used in Inst.mo
requires a mapping from variable names to locations. Unit checking can be turned off using NOSTORE
"

  record INSTSTORE
    Store store;
    HashTable.HashTable ht;
  end INSTSTORE;

  record NOSTORE "used to skip unit checking" end NOSTORE;
end InstStore;

public constant InstStore noStore = NOSTORE();

annotation(__OpenModelica_Interface="frontend");
end UnitAbsyn;
