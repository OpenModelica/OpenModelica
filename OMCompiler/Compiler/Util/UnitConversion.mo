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

encapsulated package UnitConversion
" file:        UnitConversion.mo
  package:     UnitConversion
  description: Conversion between unit strings, with the unit parser."

protected
import UnitParserExt;

public
function convertUnits
  "value_unit1 = factor*value_unit2 + offset. Units that differ in rad only
   convert where Hz makes up for it, as revolutions per second (FMI 3.0,
   section 2.4.3: 1 Hz = 2*pi rad/s)."
  input String unit1;
  input String unit2;
  output Boolean converts;
  output Real factor;
  output Real offset;
protected
  list<Integer> noms1, denoms1, tpnoms1, tpdenoms1, noms2, denoms2, tpnoms2, tpdenoms2;
  list<String> tpstrs1, tpstrs2;
  Real factor1, factor2, offset1, offset2;
  Integer rad1, hz1, rad2, hz2;
algorithm
  (noms1, denoms1, tpnoms1, tpdenoms1, tpstrs1, factor1, offset1) := UnitParserExt.str2unit(unit1);
  (noms2, denoms2, tpnoms2, tpdenoms2, tpstrs2, factor2, offset2) := UnitParserExt.str2unit(unit2);
  (rad1, hz1) := UnitParserExt.angleExponents(unit1);
  (rad2, hz2) := UnitParserExt.angleExponents(unit2);
  converts := valueEq((noms1, denoms1, tpnoms1, tpdenoms1, tpstrs1),
                      (noms2, denoms2, tpnoms2, tpdenoms2, tpstrs2));
  factor := factor2/factor1;
  offset := (offset2 - offset1)/factor1;

  if rad1 <> rad2 then
    converts := converts and rad1 + hz1 == rad2 + hz2;

    if converts then
      factor := factor*(2*3.14159265358979323846)^intReal(hz2 - hz1);
    end if;
  end if;
end convertUnits;

function derivedUnits
  "The unit symbols that convertUnits converts to and from baseUnit."
  input String baseUnit;
  output list<String> units = {};
protected
  Boolean converts;
algorithm
  UnitParserExt.str2unit(baseUnit);

  for unit in UnitParserExt.allUnitSymbols() loop
    if not stringEq(baseUnit, unit) then
      (converts, _, _) := convertUnits(baseUnit, unit);

      if converts then
        units := unit :: units;
      end if;
    end if;
  end for;
end derivedUnits;

annotation(__OpenModelica_Interface="script_util");
end UnitConversion;
