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

encapsulated package UnitParserExt

public function initSIUnits "initialize the UnitParser with the SI units"
  external "C" UnitParserExtImpl__initSIUnits() annotation(Library = "omcruntime");
end initSIUnits;

public function unit2str"Translate a unit to a string"
  input list<Integer> noms "nominators";
  input list<Integer> denoms"denominators";
  input list<Integer> tpnoms ;
  input list<Integer> tpdenoms;
  input list<String> tpstrs;
  input Real scaleFactor;
  input Real offset;
  output String res;
  external "C" res=UnitParserExt_unit2str(noms,denoms,tpnoms,tpdenoms,tpstrs,scaleFactor,offset) annotation(Library = "omcruntime");
end unit2str;

public function str2unit "Translate a unit string to a unit"
  input String res;
  output list<Integer> noms;
  output list<Integer> denoms;
  output list<Integer> tpnoms;
  output list<Integer> tpdenoms;
  output list<String> tpstrs;
  output Real scaleFactor;
  output Real offset;
  external "C" UnitParserExt_str2unit(res,noms,denoms,tpnoms,tpdenoms,tpstrs,scaleFactor,offset) annotation(Library = "omcruntime");
end str2unit;

public function allUnitSymbols
  output list<String> unitSymbols;
  external "C" unitSymbols = UnitParserExtImpl__allUnitSymbols() annotation(Library = "omcruntime");
end allUnitSymbols;

public function addBase "adds a base unit without weight"
  input String name;
  external "C" UnitParserExtImpl__addBase(name) annotation(Library = "omcruntime");
end addBase;

public function registerWeight "registers a weight to be multiplied with the weigth factor of a derived unit"
  input String name;
  input Real weight;
  external "C" UnitParserExtImpl__registerWeight(name,weight) annotation(Library = "omcruntime");
end registerWeight;


public function addDerived "adds a derived unit without weight"
  input String name;
  input String exp;
  external "C" UnitParserExtImpl__addDerived(name,exp) annotation(Library = "omcruntime");
end addDerived;

public function addDerivedWeight "adds a derived unit with weight"
  input String name;
  input String exp;
  input Real weight;
  external "C" UnitParserExtImpl__addDerivedWeight(name,exp,weight) annotation(Library = "omcruntime");
end addDerivedWeight;

public function checkpoint "copies all unitparser information to allow changing unit weights locally for a component"
   external "C" UnitParserExtImpl__checkpoint() annotation(Library = "omcruntime");
end checkpoint;

public function rollback "rollback the copy made in checkPoint call"
  external "C" UnitParserExtImpl__rollback() annotation(Library = "omcruntime");
end rollback;

public function clear "clears the unitparser from stored units"
  external "C" UnitParserExtImpl__clear() annotation(Library = "omcruntime");
end clear;

public function commit "commits all units, must be run before doing unit checking and after last unit has been added
with addBase or addDerived."
  external "C" UnitParserExtImpl__commit() annotation(Library = "omcruntime");
end commit;

annotation(__OpenModelica_Interface="frontend");
end UnitParserExt;
